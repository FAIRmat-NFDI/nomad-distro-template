from pathlib import Path

import yaml
from nomad.config import config


def test_actions_uncommented_if_plugins_exist():
    """
    Checks that if any of the plugins are of type 'action',
    then the cpu_worker or gpu_worker services are uncommented in the
    docker-compose.yaml file and the docker-publish.yml file.
    This is only a helpful check. If you're deploying actions differently
    (e.g. using Kubernetes), feel free to ignore this test failure.
    """
    config.load_plugins()
    if not config.plugins:
        return

    action_plugins = [
        entry_point
        for entry_point in config.plugins.entry_points.filtered_values()
        if entry_point.entry_point_type == "action"
    ]

    cpu_worker_required = any(
        [entry_point.task_queue == "cpu-task-queue" for entry_point in action_plugins]
    )

    gpu_worker_required = any(
        [entry_point.task_queue == "gpu-task-queue" for entry_point in action_plugins]
    )

    if cpu_worker_required or gpu_worker_required:
        base_dir = Path(__file__).parent.parent
        docker_compose_path = base_dir / "docker-compose.yaml"
        docker_publish_path = base_dir / ".github" / "workflows" / "docker-publish.yml"

        with open(docker_compose_path, "r") as f:
            docker_compose = yaml.safe_load(f)
        services = docker_compose.get("services", {})
        cpu_worker_uncommented = "cpu_worker" in services
        gpu_worker_uncommented = "gpu_worker" in services

        with open(docker_publish_path, "r") as f:
            docker_publish_content = f.read()

        cpu_build_commented = "# - service: cpu-action" in docker_publish_content
        gpu_build_commented = "# - service: gpu-action" in docker_publish_content

        if cpu_worker_required:
            assert cpu_worker_uncommented, (
                "Action plugins exist, but cpu worker is commented out in docker-compose.yaml. "
                "This is only a helpful check. If you are deploying actions differently (e.g. using Kubernetes), feel free to ignore this test failure."
            )

            assert not cpu_build_commented, (
                "Action plugins exist, but cpu action build step is commented out in docker-publish.yml."
            )

        if gpu_worker_required:
            assert gpu_worker_uncommented, (
                "Action plugins exist, but gpu worker is commented out in docker-compose.yaml. "
                "This is only a helpful check. If you are deploying actions differently (e.g. using Kubernetes), feel free to ignore this test failure."
            )

            assert not gpu_build_commented, (
                "Action plugins exist, but no gpu build action is commented in docker-publish.yml."
            )
