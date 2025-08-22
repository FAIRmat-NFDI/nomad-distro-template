from typing import TYPE_CHECKING

import pytest

from conftest import make_request_with_retry, get_request

if TYPE_CHECKING:
    from nomad.client import Auth


def test_apps_entry_points(auth: "Auth"):
    # 1. List all app entry points
    list_resp = make_request_with_retry(get_request, "apps/entry-points", auth)
    payload = list_resp.json()
    apps = payload.get("data", [])
    assert apps, "No apps returned by /apps/entry-points"

    failures: list[str] = []

    # 2. For each app, call the detail endpoint
    for app in apps:
        app_path = app.get("path")
        if not app_path:
            failures.append(f"cannot get path for {app=}")
            continue

        detail_url = f"apps/entry-points/{app_path}"
        response = make_request_with_retry(
            get_request, detail_url, auth, check_status=False
        )

        if response.status_code != 200:
            failures.append(f"app '{app_path}' failed with error: {response.text}")

    if failures:
        pytest.fail("\n".join(failures))
