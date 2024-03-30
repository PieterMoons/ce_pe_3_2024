FROM python:latest

# Install dependencies
WORKDIR /app
COPY . .

# Install python, PIP and requirements
WORKDIR /app
RUN pip install --no-cache-dir -r requirements.txt
ENV  FLASK_APP=crudapp.py


EXPOSE 80
CMD ["gunicorn" , "-b", "0.0.0.0:80", "crudapp:app"]