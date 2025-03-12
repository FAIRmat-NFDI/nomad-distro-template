import time
from nomad.client import api
from nomad.config import config

from nomad.config.models.plugins import ExampleUploadEntryPoint
import pytest


def get_example_upload_entrypoints() -> list[ExampleUploadEntryPoint]:
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
        if entry_point.id and not entry_point.from_examples_directory
    ]


@pytest.mark.parametrize(
    "entry_point_id",
    get_example_upload_ids(),
    ids=lambda entry_point_id: entry_point_id,
)
def test_example_uploads(entry_point_id, auth):
    url = f"uploads?example_upload_id={entry_point_id}"
    response = api.post(
        url,
        auth=auth,
        headers={"Accept": "application/json"},
    )
    assert response.status_code == 200, response.text
    upload_id = response.json().get("upload_id")
    url = f"uploads/{upload_id}"

    timeout = 300
    interval = 10
    start = time.time()
    processing = True

    while processing:
        if time.time() - start > timeout:
            raise TimeoutError("Example upload processing timed out")
        time.sleep(interval)
        response = api.get(
            f"uploads/{upload_id}",
            auth=auth,
            headers={"Accept": "application/json"},
        )
        assert response.status_code == 200, response.text

        upload_data = response.json()["data"]
        assert not upload_data["errors"]
        assert not upload_data["warnings"]
        if not upload_data["process_running"]:
            # Check that upload processed fine with no overall errors/warnings
            assert upload_data["process_status"] == "SUCCESS"
            processing = False

    # Check entries for errors
    response = api.post(
        "entries/query",
        auth=auth,
        json={"upload_id": upload_id},
        headers={"Accept": "application/json"},
    )
    assert response.status_code == 200, response.text
    entry_ids = [entry.entry_id for entry in response.json()["data"]]
    for entry_id in entry_ids:
        response = api.get(
            f"entries/{entry_id}/archive",
            auth=auth,
            headers={"Accept": "application/json"},
        )
        assert response.status_code == 200, response.text
        logs = response.json()["data"]["archive"]["processing_logs"]
        for log in logs:
            assert log["level"] != "ERROR"
