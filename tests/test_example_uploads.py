import os
import time

from typing import TYPE_CHECKING

import pytest
from nomad.config import config
from conftest import make_request_with_retry, get_request, post_request

if TYPE_CHECKING:
    from nomad.config.models.plugins import ExampleUploadEntryPoint


PLUGINS_TO_SKIP = os.getenv("PLUGINS_STRING", "")


def get_example_upload_entrypoints() -> list["ExampleUploadEntryPoint"]:
    """
    Retrieves information about example upload entrypoints
    """
    config.load_plugins()
    if not config.plugins:
        return []

    example_uploads = [
        entry_point
        for entry_point in config.plugins.entry_points.filtered_values()
        if entry_point.entry_point_type == "example_upload"
    ]

    return example_uploads


def get_example_upload_ids() -> list[str]:
    return [
        entry_point.id
        for entry_point in get_example_upload_entrypoints()
        if entry_point.id
        and not entry_point.from_examples_directory
        and (entry_point.plugin_package or "") not in PLUGINS_TO_SKIP
    ]


@pytest.mark.parametrize(
    "entry_point_id",
    get_example_upload_ids(),
    ids=lambda entry_point_id: entry_point_id,
)
def test_example_uploads(entry_point_id, auth):
    url = f"uploads?example_upload_id={entry_point_id}"
    response = make_request_with_retry(post_request, url=url, auth=auth)
    upload_id = response.json().get("upload_id")
    url = f"uploads/{upload_id}"

    timeout = 600
    interval = 10
    start = time.time()
    processing = True

    while processing:
        if time.time() - start > timeout:
            raise TimeoutError("Example upload processing timed out")
        time.sleep(interval)
        url = f"uploads/{upload_id}"
        response = make_request_with_retry(get_request, url=url, auth=auth)
        upload_data = response.json()["data"]
        assert not upload_data["errors"]
        assert not upload_data["warnings"]
        if not upload_data["process_running"]:
            # Check that upload processed fine with no overall errors/warnings
            assert (
                upload_data["process_status"] == "READY"
                or upload_data["process_status"] == "SUCCESS"
            )
            processing = False

    # Check entries for errors
    response = make_request_with_retry(
        post_request, url="entries/query", auth=auth, json={"upload_id": upload_id}
    )

    entry_ids = [entry.entry_id for entry in response.json()["data"]]
    for entry_id in entry_ids:
        url = (f"entries/{entry_id}/archive",)
        response = make_request_with_retry(get_request, url=url, auth=auth)
        logs = response.json()["data"]["archive"]["processing_logs"]
        for log in logs:
            assert log["level"] != "ERROR"
