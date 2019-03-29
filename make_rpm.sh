
# first define some parameters

_app_name="godot_game"
_app_icon="godot_game_template.png"
_mer_sdk_ip="localhost"
_mer_sdk_port="2222"

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
        * )
            echo "Unknown parameter $argc: "$1
        ;;
		esac
        shift
    done
    return 0
}

parse_args $@
exit $?