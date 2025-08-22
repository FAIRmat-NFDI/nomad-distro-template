from typing import TYPE_CHECKING

import pytest
from nomad.client import api
from nomad.config import config


if TYPE_CHECKING:
    from nomad.client import Auth


@pytest.fixture(scope="session")
def auth():
    from nomad.client import Auth

    return Auth(user=config.client.user, password=config.client.password, from_api=True)


def make_request_with_retry(
    request_func, url, auth, json=None, check_status: bool = True
):
    """
    Makes a request to the given URL with authentication.
    If a 401 response is received, resets the authentication token and retries once.

    Args:
        request_func: The request function (api.post or api.get).
        url: The URL to send the request to.
        auth: The authentication object.
        check_status: Check if the request returns status 200.

    Returns:
        The API response object.
    """
    response = request_func(url, auth, json)

    if response.status_code == 401:
        auth._token = None  # Reset token
        response = request_func(url, auth, json)

    if check_status:
        assert response.status_code == 200, response.text
    return response


def post_request(url: str, auth: "Auth", json=None):
    return api.post(url, auth=auth, headers={"Accept": "application/json"}, json=json)


def get_request(url: str, auth: "Auth", json=None):
    return api.get(url, auth=auth, headers={"Accept": "application/json"})
