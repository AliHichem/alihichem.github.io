
# Container instance name
AGENT_NAME := "ai-agent"

# Image tag version
IMAGE_TAG := "updated"

POD_NAME := "alihichem-pod"
NETWORK_NAME := "default"

# Default base image tag built from Dockerfile
IMAGE_BASE_TAG := "latest"
IMAGE_NAME_BASE := "ai-agent-base:" + IMAGE_BASE_TAG

# Snapshot image tag created via `just ai-commit` or `just ai-up`
PROJECT_SOURCE_DIR  := `pwd`

# Snapshot image tag created via `just ai-commit`
IMAGE_UPDATED_TAG := "updated"
IMAGE_NAME_UPDATED := "ai-agent:" + IMAGE_UPDATED_TAG
IMAGE_NAME_DEFAULT := "ai-agent:" + IMAGE_BASE_TAG

# Dynamically select the committed snapshot if present; otherwise fall back to base build
IMAGE_NAME := `podman image exists ai-agent:updated && echo "ai-agent:updated" || echo "ai-agent:latest"`

DOCKER_DIR := "docker/ai"
DOCKER_USER := "agent"
DOCKER_HOME := "/home/agent"


up: create-pod start

create-pod:
    @podman pod exists {{ POD_NAME }} || podman pod create \
        --name {{ POD_NAME }} \
        --network {{ NETWORK_NAME }} \
        --userns=keep-id \
        --cpus 6.0 \
        --memory 6g
    @echo "📦 Pod '{{ POD_NAME }}' active on network '{{ NETWORK_NAME }}'."

sh:
    @echo "🐚 Entering {{ AGENT_NAME }} shell..."
    podman exec -it  {{ AGENT_NAME }} nu

clear:
    @podman pod rm -f {{ POD_NAME }} || true
    @echo "🧹 Sandbox wiped."

start:
	@echo "🚀 Launching Agent using image '{{ IMAGE_NAME }}'..."
	@podman run -dt \
		--init \
		--pod {{ POD_NAME }} \
		--name {{ AGENT_NAME }} \
		--network {{ NETWORK_NAME }} \
		--workdir /app \
		-e IS_CONTAINER=true \
		-e WAYLAND_DISPLAY=wayland-docker \
		-e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
		-v $XDG_RUNTIME_DIR/wayland-docker:$XDG_RUNTIME_DIR/wayland-docker \
		--cpus 12 \
		--memory 20g \
		--user=agent \
		-v /run/user/$(id -u)/bus:/run/user/$(id -u)/bus \
		-e DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" \
		-v {{ PROJECT_SOURCE_DIR }}/:/app/alihichem/:z \
		-p 3001:3001 \
		--dns 1.1.1.1 --dns 8.8.8.8 \
		-v /run/user/1000/podman/podman.sock:/var/run/docker.sock \
		-v ~/.zoxide.nu:/{{ DOCKER_HOME }}/.zoxide.nu:z \
		-v ~/.bash_history_ai_container:/{{ DOCKER_HOME }}/.bash_history \
		-v ~/.config/nushell:/{{ DOCKER_HOME }}/.config/nushell:z \
		-v ~/.config/lazygit:/{{ DOCKER_HOME }}/.config/lazygit:ro,z \
		-v ~/.config/zellij:/{{ DOCKER_HOME }}/.config/zellij:ro,z \
		-v ~/.config/nvim:/{{ DOCKER_HOME }}/.config/nvim:z \
		-v ~/.local/share/nvim-aiagent:/{{ DOCKER_HOME }}/.local/share/nvim:z \
		-v ~/.local/state/nvim-aiagent:/{{ DOCKER_HOME }}/.local/state/nvim:z \
		-v ~/.config/vi-mongo:/{{ DOCKER_HOME }}/.config/vi-mongo:z \
		-v ~/.supermaven:/{{ DOCKER_HOME }}/.supermaven:z \
		-v ~/.opencode:/{{ DOCKER_HOME }}/.opencode:z \
		-v ~/.local/share/opencode:/{{ DOCKER_HOME }}/.local/share/opencode:z \
		-v ~/.local/share/kilo:/{{ DOCKER_HOME }}/.local/share/kilo:z \
		-v ~/.local/share/crush:/{{ DOCKER_HOME }}/.local/share/crush:z \
		-v ~/.gemini:/{{ DOCKER_HOME }}/.gemini:z \
		-v ~/.qwen:/{{ DOCKER_HOME }}/.qwen:z \
		-v ~/.claude:/{{ DOCKER_HOME }}/.claude:z \
		-v ~/.cursor:/{{ DOCKER_HOME }}/.cursor:z \
		-v ~/.gitconfig:/{{ DOCKER_HOME }}/.gitconfig:ro \
		--entrypoint /usr/bin/nu \
		{{ IMAGE_NAME }}
	@echo "✅ Sandbox is ready. Run 'just ai-sh' to start coding."
