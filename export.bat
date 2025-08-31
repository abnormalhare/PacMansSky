rmdir /s /q .export
7z a -tzip web.love @exportlist.txt
npx love.js web.love .export -c -t "Web"
del web.love