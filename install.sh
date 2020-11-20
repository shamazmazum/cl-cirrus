#!/bin/sh
# cl-travis install script. Don't remove this line.
set -e

# get <destination> <url(s)>
get() {
    destination=$1; shift
    for url in "$@"; do
        echo "Downloading ${url}..."
        if curl --no-progress-bar --retry 10  -o "$destination" -L "$url"; then
            return 0;
        else
            echo "Failed to download ${url}."
        fi
    done

    return 1;
}

# add_to_lisp_rc <string>
add_to_lisp_rc() {
    string=$1

    case "$LISP" in
        abcl) rc=".abclrc" ;;
        allegro*) rc=".clinit.cl" ;;
        sbcl*) rc=".sbclrc" ;;
        ccl*) rc=".ccl-init.lisp" ;;
        cmucl) rc=".cmucl-init.lisp" ;;
        clisp*) rc=".clisprc.lisp" ;;
        ecl) rc=".eclrc" ;;
        *)
            echo "Unable to determine RC file for '$LISP'."
            exit 1
            ;;
    esac

    echo "$string" >> "$HOME/.cim/init.lisp"
    echo "$string" >> "$HOME/$rc"
}

ASDF_URL="https://raw.githubusercontent.com/lispci/cl-travis/master/deps/asdf.lisp"
ASDF_LOCATION="$HOME/asdf"

install_asdf() {
    get asdf.lisp "$ASDF_URL"
    add_to_lisp_rc "(load \"$ASDF_LOCATION\")"
}

compile_asdf() {
    echo "Compiling ASDF..."
    cl -c "$ASDF_LOCATION.lisp" -Q
}

ASDF_SR_CONF_DIR="$HOME/.config/common-lisp/source-registry.conf.d"
ASDF_SR_CONF_FILE="$ASDF_SR_CONF_DIR/cl-travis.conf"
LOCAL_LISP_TREE="$HOME/lisp"

setup_asdf_source_registry() {
    mkdir -p "$LOCAL_LISP_TREE"
    mkdir -p "$ASDF_SR_CONF_DIR"

    echo "(:tree \"$CIRRUS_WORKING_DIR/\")" > "$ASDF_SR_CONF_FILE"
    echo "(:tree \"$LOCAL_LISP_TREE/\")" >> "$ASDF_SR_CONF_FILE"

    echo "Created $ASDF_SR_CONF_FILE"
    cat -n "$ASDF_SR_CONF_FILE"
}

# install_script <path> <lines...>
install_script() {
    path=$1; shift
    tmp=$(mktemp)

    echo "#!/bin/sh" > "$tmp"
    for line; do
        echo "$line" >> "$tmp"
    done
    chmod 755 "$tmp"

    sudo mv "$tmp" "$path"
}

install_sbcl() {
    echo "Installing SBCL..."
    pkg install -y sbcl
    cim use sbcl-system --default
}

install_clisp() {
    echo "Installing CLISP..."
    pkg install -y clisp
    cim use clisp-system --default
}

install_ccl() {
    echo "Installing CCL..."
    pkg install -y ccl
    cim use ccl-system --default
}

QUICKLISP_URL="http://beta.quicklisp.org/quicklisp.lisp"

install_quicklisp() {
    get quicklisp.lisp "$QUICKLISP_URL"
    echo 'Installing Quicklisp...'
    cl -f quicklisp.lisp -e '(quicklisp-quickstart:install)'
    add_to_lisp_rc '(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                                           (user-homedir-pathname))))
                      (when (probe-file quicklisp-init)
                        (load quicklisp-init)))'
}

# this variable is used to grab a specific version of the
# cim_installer which itself looks at this variable to figure out
# which version of CIM it should install.
CIM_INSTALL_BRANCH=c9f4ea960ce4504d5ddd229b9f0f83ddc6dce773
CL_SCRIPT="/usr/local/bin/cl"
CIM_SCRIPT="/usr/local/bin/cim"
QL_SCRIPT="/usr/local/bin/ql"

install_cim() {
    curl -L "https://raw.github.com/sionescu/CIM/$CIM_INSTALL_BRANCH/scripts/cim_installer" | /bin/sh

    install_script "$CL_SCRIPT"  ". \"$HOME\"/.cim/init.sh; exec cl  \"\$@\""
    install_script "$CIM_SCRIPT" ". \"$HOME\"/.cim/init.sh; exec cim \"\$@\""
    install_script "$QL_SCRIPT"  ". \"$HOME\"/.cim/init.sh; exec ql  \"\$@\""
}

(
    cd "$HOME"

    install_cim
    install_asdf

    case "$LISP" in
        sbcl) install_sbcl ;;
        ccl) install_ccl ;;
        clisp) install_clisp ;;
        *)
            echo "Unrecognised lisp: '$LISP'"
            exit 1
            ;;
    esac

    compile_asdf

    cl -e '(format t "~%~a ~a up and running! (ASDF ~a)~%~%"
                   (lisp-implementation-type)
                   (lisp-implementation-version)
                   (asdf:asdf-version))'

    install_quicklisp
    setup_asdf_source_registry
)
