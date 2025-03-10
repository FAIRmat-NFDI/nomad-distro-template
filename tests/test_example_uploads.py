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
    start_time = time.time()

    while time.time() - start_time < timeout:
        response = api.get(url, auth=auth, headers={"Accept": "application/json"})
        if response.ok:
            upload_data = response.json().get("data", {})
            assert not upload_data.get("errors", [])
            assert not upload_data.get("warnings", [])
            running = upload_data.get("process_running")
            if not running:
                return True
        time.sleep(interval)

    assert False
