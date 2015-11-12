# Copy all files (not directories) in a certain directory in /vagrant over to
# the guest VM, creating directories where necessary.
# > copy_function /etc/mesos
# => cp /vagrant/etc/mesos/<files> /etc/mesos/<files>
function copy_config() {
    for dir in $@; do
        mkdir -p "$dir"
        for src in $(find "/vagrant${dir}" -type f -maxdepth 1); do
            cp "$src" "$dir/$(basename $src)"
        done
    done
}
