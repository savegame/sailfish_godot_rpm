
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
_release="1"
_changelog=""
_changelog_text=""

IFS='' read -r -d '' spec_file_data <<"EOF"
Name:       $application_name$
Summary:    $application_long_name$
Version:    $version$
Release:    $release$
Group:      Godot
License:    LICENSE
BuildArch:  $architecture$
URL:        http://example.org/
#Source0:    %{name}.tar.xz
Requires:   SDL2
Requires:   freetype
Requires:   libpng
Requires:   openssl
Requires:   zlib
Requires:   glib2
Requires:   libaudioresource
#Requires:   libkeepalive-glib

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
%defattr(644,root,root,-)
%attr(755,root,root) %{_bindir}/%{name}
%attr(644,root,root) %{_datadir}/%{name}/%{name}.png
%attr(644,root,root) %{_datadir}/%{name}/%{name}.pck
%attr(644,root,root) %{_datadir}/applications/%{name}.desktop

%changelog 
* $date$ Godot Game Engine
- application $application_name$ packed to RPM
$changelog$
EOF

IFS='' read -r -d '' desktop_file_data <<"EOF"
[Desktop Entry]
Type=Application
X-Nemo-Application-Type=SDL2 
Icon=/usr/share/$application_name$/$application_name$.png
Exec=/usr/bin/$application_name$ --main-pack /usr/share/$application_name$/$application_name$.pck
Name=$application_long_name$
Name[en]=$application_long_name$
EOF

IFS='' read -r -d '' help_data <<"EOF"
Make RPM script v 1.0.3
    -pck/--pck      <path>      path to  *.pck game archive (need export project to pck)
    -g/--godot      <path>      path to spicific for target platform godot binary (arm or x86)
    -icon/--icon    <path>      path to icon PNG file
    -n/--name       <string>    rpm name (should be without spaces or any special symbols) 
                                matches: [a-z_\-0-9\.]+
    -ln/--long-name <string>    Game name, its would be show in Apps Menu 
    -v/--version    <string>    application version (1.0.0 default)
    -r/--release    <string>    application release number (1 by default)
    -c/--changelog  <path>      path to changelog text file (it add to end of spec)
EOF

function print_help() 
{
    echo "$help_data"
}

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
        "-v" | "--version" )
            shift 
            _version="$1"
        ;;
        "-r" | "--release" )
            shift
            _release="$1"
        ;;
        "-c" | "--changelog" )
        	shift
        	_changelog="$1"
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
    local error_=0
    if [ -z $_pck_file ] ; then 
        echo "You should set path to pck file by --pck <path>"
        error_=1
    fi

    if [ -z $_godot_binary ] ; then 
        echo "You should set path to godot export template binary by -g/--godot <path>"
        error_=1
    fi

    if [ -z $_app_icon ] ; then 
        echo "You should set path to game icon file by --icon <path> (PNG file)"
        error_=1
    fi

    if [ -z "$_app_long_name" ] ; then
        echo "You dont set Appliction Human Readable Name, set app_name"
        _app_long_name="${_app_name}"
    fi

    [ $error_ -ne 0 ] && print_help || echo -n ""

    return $error_
}

function check_mer_target() 
{
    local target_count=0
    local option
    if [ -z "$_mer_target" ] ; then
        echo "Mer target is not setuped, please choose one: "
        local targets="`sb2-config -l`"
        local binary_suffix=`echo "$_godot_binary"|sed -e "s~.*godot\.sailfish\.opt\.\(arm\|x86\)~\1~g"`

        for target in $targets ; do
            local target_suffix=`echo "$target"|sed -e "s~SailfishOS-[0-9\.]\+-\(armv7hl\|i486\)~\1~g"`
            # echo "target_suffix = $target_suffix"
            local add_this_target=1
            if [ ! -z "$target_suffix" -a ! -z "$binary_suffix" ] ; then
                add_this_target=0
                if [ "$binary_suffix" == "arm" ] ; then
                    if [ "$target_suffix" == "armv7hl" ] ; then
                        add_this_target=1
                    else 
                        add_this_target=0
                    fi
                elif [ "$binary_suffix" == "x86" ] ; then
                    if [ "$target_suffix" == "i486" ] ; then
                        add_this_target=1
                    else 
                        add_this_target=0
                    fi
                else
                    add_this_target=1
                fi
            fi
            if [ $add_this_target -eq 1 ] ; then 
                eval option[${target_count}]=$target
                ((target_count++))
            fi
        done
        # dont use all targets, bacuse we have only for one target binary
        # eval option[${target_count}]=\"All targets\"
        # ((target_count++))
        if [ $target_count -eq 1 ] ; then
            _mer_target="${option[0]}"
            echo "Automatically choose \"$_mer_target\""
        else
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
        local arch=`echo $_mer_target|sed -e 's~.*\(i486\|armv7hl\)~\1~g'`
        echo "Use architecture: $arch"
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
        # right path for icon is 
        # /usr/share/icons/hicolor/[0-9x]{5,9}/apps/${_app_name}.png
        # echo -n "Icon folder: "
        # LC_ALL=en_US.UTF-8 exiv2 $_app_icon | grep Image\ size|sed -e "s~Image size \+: \+~~g" -e "s~ ~~g"
        rsync -aP $_app_icon "${current_build_root}"/BUILD/usr/share/$_app_name/$_app_name.png
        [ $? -ne 0 ] && return 1
        
        echo "Generate ${_app_name}.desktop file."
        echo "$desktop_file_data"|sed -e "s~\\\$application_name\\\$~$_app_name~g" -e "s~\\\$application_long_name\\\$~$_app_long_name~g">"${current_build_root}"/BUILD/usr/share/applications/${_app_name}.desktop
        local spec_file_path="${current_build_root}/SPECS/${_app_name}.spec"

        echo "Generate ${_app_name}.spec file."
        if [ -n "$_changelog" ] ; then
            if [ -f $_changelog ] ; then
                #_changelog_text="$(cat $_changelog)"
                while IFS='' read line
                do
                spec_file_data="$(echo "$spec_file_data"|sed -e "s~\\\$changelog\\\$~${line} \n\$changelog\$~g")" 
                done < $_changelog
                spec_file_data="$(echo "$spec_file_data"|sed -e "s~\\\$changelog\\\$~~g")"
            fi
        fi

        echo "$spec_file_data"|sed -e "s~\\\$application_name\\\$~$_app_name~g" -e "s~\\\$application_long_name\\\$~$_app_long_name~g" -e "s~\\\$version\\\$~$_version~g" -e "s~\\\$release\\\$~$_release~g" -e "s~\\\$date\\\$~${current_date}~g" -e "s~\\\$changelog\\\$~'${_changelog_text}'~g" -e "s~\\\$architecture\\\$~${arch}~g">"${spec_file_path}"

        echo "Pack all data to RPM file."
        ${sb2_command} rpmbuild --define  "_topdir ${current_build_root}" -ba "${current_build_root}/SPECS/${_app_name}.spec" &> "${_pwd}/rpmbuild_${_app_name}.log"
        if [ $? -ne 0 ] ; then
            echo "We have Error! Look in to ${_pwd}/rpmbuild_${_app_name}.log"
        fi
    done
}

parse_args "$@"
check_args
[ $? -ne 0 ] && exit 1
prepare_build_folder
exit $?
