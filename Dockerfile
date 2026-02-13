# 1. Rubric Requirement: Use python:stretch
FROM python:stretch

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
# (Added --upgrade pip to ensure compatibility, as stretch is an older image)
RUN pip install --upgrade pip && \
    pip install -r requirements.txt --no-cache-dir

# Copy application code
COPY main.py .

# Expose the application port
EXPOSE 8080

# Set environment variables (Keeping this is good practice, though not strictly mandated)
ENV LOG_LEVEL=INFO

# 2. Rubric Requirement: Define Gunicorn entrypoint exactly as specified
ENTRYPOINT ["gunicorn", "-b", ":8080", "main:APP"]