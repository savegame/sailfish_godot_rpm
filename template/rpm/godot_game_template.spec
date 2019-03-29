Name:       $application_name$
Summary:    Godot Game Engine
Version:    3.1.beta
Release:    1
Group:      Godot
License:    LICENSE
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.xz
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
$description$


%prep
#%setup -q -n %{name}-%{version}
tar xJvf %{name}-%{version}.tar.xz

# >> setup
# << setup

%build
cd %{_topdir}/BUILd

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/%{name}


%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
# >> files
# << files
