
# first define some parameters
_pwd=`dirname $(readlink -e "$0")`

_app_name="godot_game"
_app_long_name=""
_app_icon=""
_mer_sdk_ip="localhost"
_mer_sdk_port="2222"
_mer_target=""
_pck_file=""
_godot_binary=""
_version="1.0.0"

IFS='' read -r -d '' spec_file_data <<"EOF"
Name:       $application_name$
Summary:    $application_long_name$
Version:    $version$
Release:    1
Group:      Godot
License:    LICENSE
URL:        http://example.org/
#Source0:    %{name}.tar.xz
Requires:   SDL2
Requires:   freetype
Requires:   libpng
Requires:   openssl
Requires:   zlib
Requires:   libvpx
Requires:   libwebp
Requires:   glib2
Requires:   libaudioresource

%description
This game made with Godot Game Engine! Godot Engine version 3.1

%prep
echo "Nothing to do here. Skip this step"

%build
cd %{_topdir}/BUILD
echo "Nothing to do here. Skip this step"

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
cp -r %{_topdir}/BUILD/usr %{buildroot}/

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop

%changelog 
* $date$ Godot Game Engine
- application $application_name$ packed to RPM
EOF

IFS='' read -r -d '' desktop_file_data <<"EOF"
[Desktop Entry]
Type=Application
X-Nemo-Application-Type=sdl2
Icon=/usr/share/$application_name$/$application_name$.png
Exec=/usr/bin/$application_name$ --main-pack /usr/share/$application_name$/$application_name$.pck
Name=$application_long_name$
Name[en]=$application_long_name$
EOF

function parse_args() 
{
    local argc=0

    while [ $# -gt 0 ] ; do	
        ((argc++))
        case "$1" in
        "-t" | "--target" )
            shift
            _mer_target="$1"
        ;;
        "-pck" | "--pck" )
            shift
            _pck_file="$1"
        ;;
        "-g" | "--godot" )
            shift 
            _godot_binary="$1"
        ;;
        "-icon" | "--icon" )
            shift
            _app_icon="$1"
        ;;
        "-n" | "--name" )
            shift 
            _app_name="$1"
        ;;
        "-ln" | "--long-name" )
            shift 
            _app_long_name="$1"
        ;;
        * )
            echo "Unknown parameter $argc: $1"
        ;;
		esac
        shift
    done
    return 0
}

function check_args()
{
    if [ -z $_pck_file ] ; then 
        echo "You should set path to pck file by --pck <path>"
        return 1
    fi

    if [ -z $_godot_binary ] ; then 
        echo "You should set path to godot export template binary by -g/--godot <path>"
        return 1
    fi

    if [ -z $_app_icon ] ; then 
        echo "You should set path to game icon file by --icon <path> (PNG file)"
        return 1
    fi

    if [ -z $_app_long_name ] ; then
        echo "You dont set Appliction Human Readable Name, set app_name"
        _app_long_name="${_app_name}"
    fi

    return 0
}

function check_mer_target() 
{
    local target_count=0
    local option
    if [ -z "$_mer_target" ] ; then
        echo "Mer target is not setuped, please choose one: "
        local target="`sb2-config -l`"
        for target in $target ; do
            eval option[${target_count}]=$target
            ((target_count++))
        done
        # dont use all targets, bacuse we have only for one target binary
        # eval option[${target_count}]=\"All targets\"
        # ((target_count++))
        select opt in "${option[@]}" ; do
            if [ -z "$opt" ] ; then
                echo "Invalid option $REPLY"
            elif [[ $opt == "All targets" ]] ; then
                echo "You choose all targets."
                _mer_target="`sb2-config -l`"
                break
            else
                echo "You  choose \"$opt\" target."
                _mer_target=$opt
                break
            fi
        done
    fi
}

function prepare_build_folder() 
{
    check_mer_target
    local current_target=""
    local current_date="`LC_ALL=en_EN.UTF-8 date "+%a %b %d %Y"`"

    for current_target in ${_mer_target} ; do
        local current_build_root="${_pwd}/buildroot/$current_target"
        local sb2_command="sb2 -t $current_target "

        echo "Current target is \"$current_target\""
        # clear build folder 
        if [ -d ${current_build_root} ] ; then
            echo "Remove old build dir."
            rm -fr ${current_build_root}
        fi

        # create RPM build folders 
        echo "Create directories {SOURCES,BUILD,SPECS} in ${current_build_root}."
        mkdir -p "${current_build_root}"/{SOURCES,BUILD,SPECS}
        mkdir -p "${current_build_root}"/BUILD/usr/{bin,share}
        mkdir -p "${current_build_root}"/BUILD/usr/share/{$_app_name,applications}        
        # need make normal icons folder like /usr/share/icons/86x86/my_app_game.png
        #${sb2_command} mkdir -p "${current_build_root}"/BUILD/usr/share/icons/{86x86,108x108,128x128,256x256}

        # copy game resources
        echo "Copy game resources to build rpm directory."
        rsync -aP $_godot_binary "${current_build_root}"/BUILD/usr/bin/$_app_name
        [ $? -ne 0 ] && return 1
        rsync -aP $_pck_file "${current_build_root}"/BUILD/usr/share/$_app_name/$_app_name.pck
        [ $? -ne 0 ] && return 1
        rsync -aP $_app_icon "${current_build_root}"/BUILD/usr/share/$_app_name/$_app_name.png
        [ $? -ne 0 ] && return 1
        
        echo "Generate ${_app_name}.desktop file."
        echo "$desktop_file_data"|sed -e "s~\\\$application_name\\\$~$_app_name~g" -e "s~\\\$application_long_name\\\$~$_app_long_name~g">"${current_build_root}"/BUILD/usr/share/applications/${_app_name}.desktop
        local spec_file_path="${current_build_root}/SPECS/${_app_name}.spec"

        echo "Generate ${_app_name}.spec file."
        echo "$spec_file_data"|sed -e "s~\\\$application_name\\\$~$_app_name~g" -e "s~\\\$application_long_name\\\$~$_app_long_name~g" -e "s~\\\$version\\\$~$_version~g" -e "s~\\\$date\\\$~${current_date}~g">"${spec_file_path}"

        #echo "Create empty ${_app_name}.tar.gz archive"
        #touch "${current_build_root}/SOURCES/${_app_name}.tar.gz"

        echo "Pack all data to RPM file."
        ${sb2_command} rpmbuild --define  "_topdir ${current_build_root}" -ba "${current_build_root}/SPECS/${_app_name}.spec" &>"${_pwd}/rpmbuild_${_app_name}.log"
    done
}

parse_args "$@"
check_args
[ $? -ne 0 ] && exit 1
prepare_build_folder
exit $?