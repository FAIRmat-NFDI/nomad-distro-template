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
        if entry_point.id and "pynxtools" in entry_point.id
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
