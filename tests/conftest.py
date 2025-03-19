import pytest
from nomad.config import config


@pytest.fixture(scope="session")
def auth():
    from nomad.client import Auth

    return Auth(user=config.client.user, password=config.client.password, from_api=True)
