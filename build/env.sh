#export FC=gfortran
#export FC_EXE=gfortran
#export INCLUDES='-I/opt/homebrew/Cellar/netcdf-fortran/x.x.x/include -I/opt/homebrew/Cellar/lapack/x.x.x/include'
#export LIBRARIES='-L/opt/homebrew/Cellar/netcdf-fortran/x.x.x/lib -lnetcdff -L/opt/homebrew/Cellar/lapack/x.x.x/lib -lblas -llapack'
export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)

export F_MASTER='/Users/william/Documents/projects/summa/summa/'

export CC='/opt/homebrew/bin/gcc-14'
export CXX='/opt/homebrew/bin/g++-14'

export FC='gfortran'
export FC_EXE='/opt/homebrew/bin/gfortran-14'
export F77='/opt/homebrew/bin/gfortran-14'


alias gcc='gcc-14'
alias gfortran='gfortran-14'

export LDFLAGS="-L/opt/homebrew/opt/lapack/lib"
export CPPFLAGS="-I/opt/homebrew/opt/lapack/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/lapack/lib/pkgconfig"
  

export LDFLAGS="-L/opt/homebrew/opt/lapack/lib -L/opt/homebrew/opt/openblas/lib"
export CPPFLAGS="-I/opt/homebrew/opt/lapack/include -I/opt/homebrew/opt/openblas/include"



export INCLUDES='-I/opt/homebrew/Cellar/netcdf-fortran/4.6.2/include -I/opt/homebrew/Cellar/lapack/3.12.1/include'
export LIBRARIES='-L/opt/homebrew/Cellar/netcdf-fortran/4.6.2/lib -lnetcdff -L/opt/homebrew/Cellar/lapack/3.12.1/lib -lblas -llapack'


export FLAGS_SUMMA="-O2 -fPIC -I/opt/homebrew/include -L/opt/homebrew/lib"

