
# first define some parameters
_pwd=`dirname $(readlink -e "$0")`

_app_name="godot_game"
_app_icon="godot_game_template.png"
_mer_sdk_ip="localhost"
_mer_sdk_port="2222"
_mer_target=""

IFS='' read -r -d '' spec_file_data <<"EOF"
#Hello world
Name:    $appname$_$version$
Summary: $appname$ package
Version: 2.65
Release: 1%{?dist}

License: NOT
Source0: $appname$.tar.xz
AutoReq: yes

BuildArch: x86_64
BuildRoot: %{_topdir}/

%description
$appname$. Based on Godot Engine

%prep
mkdir -p $RPM_BUILD_ROOT/
cd $RPM_BUILD_ROOT
tar xJf  %{_topdir}/SOURCES/$libname$.tar.xz

%build 
cd $RPM_BUILD_ROOT


%install 
 

%files
%defattr(-,root,root)


%clean 
rm -fr %RPM_BUILD_ROOT

%changelog 
* Tue Feb 12 2019 $app_name$
- создан spec для $app_name$
EOF

function parse_args() 
{
    local argc=0

    while [ $# -gt 0 ] ; do	
        ((argc++))
        case "$1" in
        "-t" | "--target" )
            shift
            _mer_target=$1
        ;;
        * )
            echo "Unknown parameter $argc: "$1
        ;;
		esac
        shift
    done
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
        eval option[${target_count}]=\"All targets\"
        ((target_count++))
        select opt in "${option[@]}" ; do
            # case $opt in 
            #     *) echo "invalid option: $opt" ;;
            # esac 
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
    for current_target in ${_mer_target} ; do
        local current_build_root="${_pwd}/buildroot/$current_target"
        local sb2_command="sb2 -t $current_target "
        echo "Current target is \"$current_target\""
        # clear build folder 
        if [ -f ${current_build_root} ] ; then
            echo "Remove old build dir."
            ${sb2_command} rm -fr ${current_build_root}
        fi
        # create RPM build folders 
        echo "Create directories {SOURCES,SPECS} in ${current_build_root}."
        ${sb2_command} mkdir ${current_build_root}/{SOURCES,SPECS}
    done
}

parse_args $@
prepare_build_folder
exit $?