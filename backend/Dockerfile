# syntax=docker/dockerfile:1
FROM python:3.14-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1
WORKDIR /backend
COPY app ./app
COPY scripts ./scripts
COPY tests ./tests
COPY alembic.ini ./alembic.ini
COPY pyproject.toml ./pyproject.toml
COPY README.md ./README.md
COPY .gitignore ./
COPY .dockerignore ./
RUN set -eu; \
    python -m pip install --no-cache-dir --upgrade pip; \
    if [ -f uv.lock ]; then \
      pip install --no-cache-dir uv && \
      uv export --frozen --no-dev --no-hashes --no-emit-project -o /tmp/requirements.txt && \
      pip install --no-cache-dir -r /tmp/requirements.txt; \
    elif [ -f pyproject.toml ] && [ -f poetry.lock ]; then \
      pip install --no-cache-dir poetry && \
      poetry config virtualenvs.create false --local && \
      poetry install --only main --no-interaction --no-ansi --no-root; \
    elif [ -f Pipfile.lock ]; then \
      pip install --no-cache-dir pipenv && \
      pipenv install --deploy --system; \
    elif [ -f requirements.txt ]; then \
      pip install --no-cache-dir -r requirements.txt; \
    elif [ -f pyproject.toml ]; then \
      if grep -q '^\[build-system\]' pyproject.toml; then \
        pip install --no-cache-dir .; \
      else \
        pip install --no-cache-dir uv && uv pip install --system --no-cache -r pyproject.toml; \
      fi; \
    else \
      echo "ERROR: no Python packaging file found (uv.lock, poetry.lock, Pipfile.lock, requirements.txt or pyproject.toml)" >&2; \
      exit 1; \
    fi
RUN pip install --no-cache-dir "uvicorn[standard]"
RUN useradd --create-home --uid 10001 appuser && chown -R appuser /backend
USER 10001
EXPOSE 8000
CMD bash scripts/prestart.sh && uvicorn app.main:app --host 0.0.0.0 --port 8000
