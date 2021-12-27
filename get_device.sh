# follow https://unix.stackexchange.com/a/634849
getdevice() {
    idV=${1%:*}
    idP=${1#*:}
    for path in `find /sys/ -name idVendor 2>/dev/null | rev | cut -d/ -f 2- | rev`; do
        if grep -q $idV $path/idVendor; then
            if grep -q $idP $path/idProduct; then
                find $path -name 'device' | rev | cut -d / -f 2 | rev
            fi
        fi
    done
}
