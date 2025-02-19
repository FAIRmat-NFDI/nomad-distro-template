from nomad.client import api
from nomad.config import config

from nomad.config.models.plugins import ExampleUploadEntryPoint


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


def test_example_uploads(auth):
    example_upload_entrypoints = get_example_upload_entrypoints()
    for entry_point in example_upload_entrypoints:
        if entry_point.id and "pynxtools" not in entry_point.id:
            continue
        url = f"uploads?example_upload_id={entry_point.id}"
        response = api.post(
            url,
            auth=auth,
            headers={"Accept": "application/json"},
        )
        assert response.status_code == 200, response.text
