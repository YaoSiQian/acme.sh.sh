FROM neilpang/acme.sh

# Overwrite the entry.sh
COPY entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["daemon"]