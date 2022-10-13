FROM python:3.9 as base

WORKDIR /usr/src/app
ENV PYTHONIOENCODING  utf-8
ARG TIMEZONE=America/Sao_Paulo
ARG LOCALE=pt_BR.UTF-8

# Set Timezone
RUN echo "Setting default timezone to $TIMEZONE"
ENV TZ=$TIMEZONE
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN echo "$TIMEZONE" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# Configure locale
RUN echo "Set default locale to $LOCALE"
RUN apt-get update && apt-get install -y locales graphviz graphviz-dev && rm -rf /var/lib/apt/lists/*
RUN echo "$LOCALE UTF-8" >> /etc/locale.gen
RUN locale-gen
RUN export LANGUAGE="$LOCALE"; export LANG="$LOCALE"; export LC_ALL="$LOCALE"; locale-gen "$LOCALE"; DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

COPY requirements.txt ./
RUN pip install -r requirements.txt

COPY . .

# Install graphs support
#RUN pip install --no-cache-dir -e ".[graphs]"

#CMD [ "python", "./setup.py" , "develop" ]

FROM base as testing
# Need to clean these files in order for the tests to work
RUN find . -name '*.py[odc]' -type f -delete
RUN find . -name '__pycache__' -type d -delete
RUN rm -rf *.egg-info .cache .eggs build dist dists

# Run testing dependencies for the container
RUN pip install --no-cache-dir -e ".[testing]"

FROM base as jupyter
ARG USERNAME=user-name-goes-here
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

ENV PORT=8888
ENV USERNAME=$USERNAME

RUN pip install jupyterlab

USER $USERNAME
ENTRYPOINT jupyter lab --app_dir=/usr/src/app --no-browser --port=${PORT} --allow-root --ip=0.0.0.0

FROM base as docs

RUN pip install --no-cache-dir -e ".[docs]"

