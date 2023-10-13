FROM python:3.11-slim-bookworm as base
WORKDIR /wheels
COPY ./requirements.txt .
RUN sed -i s@/deb.debian.org/@/mirrors.163.com/@g /etc/apt/sources.list.d/debian.sources \
	&& apt-get clean
RUN apt-get update && \
    apt-get install -y \
	default-libmysqlclient-dev \
	libmariadb3 \
	gcc
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/ \
	&& pip config set install.trusted-host pypi.tuna.tsinghua.edu.cn 
RUN pip install -U pip \
	&& pip install --no-cache-dir wheel \
	&& pip wheel --no-cache-dir --wheel-dir=/wheels -r requirements.txt

FROM python:3.11-slim-bookworm 
ENV PYTHONUNBUFFERED 1
COPY --from=base /wheels /wheels
COPY --from=base /usr/lib/x86_64-linux-gnu/libmariadb.so.3 /usr/lib/x86_64-linux-gnu/
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/ \
	&& pip config set install.trusted-host pypi.tuna.tsinghua.edu.cn 
RUN pip install -U pip \
	&& pip install -f /wheels -r /wheels/requirements.txt \
	&& rm -rf /wheels \
	&& rm -rf /root/.cache/pip/*
WORKDIR /app
ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["uwsgi", "--ini=/app/uwsgi.ini"]