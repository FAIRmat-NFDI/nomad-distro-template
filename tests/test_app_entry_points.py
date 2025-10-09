from typing import TYPE_CHECKING
import pytest

from conftest import make_request_with_retry, get_request

if TYPE_CHECKING:
    from nomad.client import Auth


@pytest.fixture(scope="module")
def apps(auth: "Auth"):
    """The list of app entrypoints."""
    resp = make_request_with_retry(get_request, "apps/entry-points", auth)
    payload = resp.json()
    apps = payload.get("data", [])
    assert apps, "No apps returned by /apps/entry-points"
    return apps


@pytest.mark.parametrize(
    "app",
    [pytest.param(a, id=a.get("path", "<no-path>")) for a in make_request_with_retry(get_request, "apps/entry-points", auth=None).json().get("data", [])],
)
def test_app_entry_point(auth: "Auth", app):
    """Each app entry point should respond successfully."""
    app_path = app.get("path")
    if not app_path:
        pytest.skip(f"App without path: {app}")

    detail_url = f"apps/entry-points/{app_path}"
    resp = make_request_with_retry(get_request, detail_url, auth, check_status=False)
    assert resp.status_code == 200, f"App '{app_path}' failed: {resp.text}"
