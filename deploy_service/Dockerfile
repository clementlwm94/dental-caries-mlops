FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install uv
RUN pip install uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen

# Copy application files
COPY service_test.py predict_function.py ./
COPY templates/ ./templates/

# Expose port
EXPOSE 9696

# Run the application with gunicorn
CMD ["uv", "run", "gunicorn", "--bind=0.0.0.0:9696", "service_test:app"]
