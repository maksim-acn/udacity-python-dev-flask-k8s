# Use AWS SAM Python 3.7 base image
FROM public.ecr.aws/sam/build-python3.7:latest

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .

# Expose the application port
EXPOSE 8080

# Set environment variables
ENV LOG_LEVEL=INFO

# Run the application with Gunicorn
ENTRYPOINT ["gunicorn", "-b", ":8080", "main:APP"]
