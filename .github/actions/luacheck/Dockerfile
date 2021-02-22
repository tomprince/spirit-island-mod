FROM fedora:33 as lua-filesystem
# Note `findutils` should be a dependency of luarocks
RUN dnf install -y lua lua-devel luarocks findutils gcc make
RUN luarocks build --pack-binary-rock luafilesystem

FROM fedora:33 as luacheck

RUN dnf install -y lua lua-devel luarocks findutils
COPY --from=lua-filesystem /*.rock /rocks/
RUN luarocks install /rocks/*.rock
RUN luarocks install luacheck

COPY luacheck-matcher.json /code/luacheck-matcher.json
COPY entrypoint.sh /code/entrypoint.sh
ENTRYPOINT ["/code/entrypoint.sh"]
