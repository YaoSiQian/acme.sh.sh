FROM neilpang/acme.sh

RUN apk add --no-cache bash

# Overwrite the entry.sh
COPY entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["daemon"]