! SUMMA - Structure for Unifying Multiple Modeling Alternatives
! Copyright (C) 2014-2020 NCAR/RAL; University of Saskatchewan; University of Washington
!
! This file is part of SUMMA
!
! For more information see: http://www.ral.ucar.edu/projects/summa
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

module conv_funcs_module
USE nrtype                                 ! variable types
USE multiconst                             ! fixed parameters (lh vapzn, etc.)
implicit none
private
public::RELHM2SPHM,SPHM2RELHM,WETBULBTMP,satVapPress,vapPress,getLatentHeatValue
contains

! ----------------------------------------------------------------------
! series of functions to convert one thing to another
! (partially courtesy of Drew Slater)
! ----------------------------------------------------------------------

! ***************************************************************************************************************
! public function getLatentHeatValue: get appropriate latent heat of sublimation/vaporization for a given surface
! ***************************************************************************************************************
function getLatentHeatValue(T)
implicit none
real(rkind),intent(in)   :: T                    ! temperature (K)
real(rkind)              :: getLatentHeatValue   ! latent heat of sublimation/vaporization (J kg-1)
if(T > Tfreeze)then
 getLatentHeatValue = LH_vap     ! latent heat of vaporization          (J kg-1)
else
 getLatentHeatValue = LH_sub     ! latent heat of sublimation           (J kg-1)
end if
end function getLatentHeatValue


! ***************************************************************************************************************
! public function vapPress: convert specific humidity (g g-1) to vapor pressure (Pa)
! ***************************************************************************************************************
function vapPress(q,p)
implicit none
! input
real(rkind),intent(in)   :: q        ! specific humidity (g g-1)
real(rkind),intent(in)   :: p        ! pressure (Pa)
! output
real(rkind)              :: vapPress ! vapor pressure (Pa)
! local
real(rkind)              :: w        ! mixing ratio
!real(rkind),parameter    :: w_ratio = 0.622_rkind ! molecular weight ratio of water to dry air (-)
w = q / (1._rkind - q)                ! mixing ratio (-)
vapPress = (w/(w + w_ratio))*p     ! vapor pressure (Pa)
end function vapPress


! ***************************************************************************************************************
! public subroutine satVapPress: Uses Teten's formula to compute saturated vapor pressure (Pa)
! ***************************************************************************************************************
! NOTE: temperature units are degC !!!!
! ***************************************************************************************************************
subroutine satVapPress(TC, SVP, dSVP_dT)
IMPLICIT NONE
! input
real(rkind), intent(in)            :: TC       ! temperature (C)
! output
real(rkind), intent(out)           :: SVP      ! saturation vapor pressure (Pa)
real(rkind), intent(out)           :: dSVP_dT  ! d(SVP)/dT
! local
real(rkind), parameter             :: X1 = 17.27_rkind
real(rkind), parameter             :: X2 = 237.30_rkind
! local (use to test derivative calculations)
real(rkind),parameter              :: dx = 1.e-8_rkind     ! finite difference increment
logical(lgt),parameter          :: testDeriv=.false. ! flag to test the derivative
!---------------------------------------------------------------------------------------------------
! Units note :              Pa = N m-2 = kg m-1 s-2
! SATVPFRZ=     610.8       ! Saturation water vapour pressure at 273.16K (Pa)

SVP     = SATVPFRZ * EXP( (X1*TC)/(X2 + TC) ) ! Saturated Vapour Press (Pa)
dSVP_dT = SVP * (X1/(X2 + TC) - X1*TC/(X2 + TC)**2._rkind)
if(testDeriv) print*, 'dSVP_dT check... ', SVP, dSVP_dT, (SATVPRESS(TC+dx) - SVP)/dx
END SUBROUTINE satVapPress



! ***************************************************************************************************************
! public subroutine satVapPressIce: Use Huang's formula to compute saturated vapor pressure over ice (Pa)
! ***************************************************************************************************************
! NOTE: temperature units are degC !!!!
! ***************************************************************************************************************
subroutine satVapPressIce(TC, SVP, dSVP_dT)
IMPLICIT NONE
! input
real(rkind), intent(in)            :: TC       ! temperature (C)
! output
real(rkind), intent(out)           :: SVP      ! saturation vapor pressure (Pa)
real(rkind), intent(out)           :: dSVP_dT  ! d(SVP)/dT

! local (use to test derivative calculations)
real(rkind),parameter              :: dx = 1.e-8_rkind     ! finite difference increment
logical(lgt),parameter          :: testDeriv=.false. ! flag to test the derivative
!---------------------------------------------------------------------------------------------------
! Units note :              Pa = N m-2 = kg m-1 s-2
! SATVPFRZ=     610.8       ! Saturation water vapour pressure at 273.16K (Pa)

!SVP     = SATVPFRZ * EXP( (X1*TC)/(X2 + TC) ) ! Saturated Vapour Press (Pa)
! t is in C
SVP = 1000._rkind * EXP(43.494_rkind - 6545.8_rkind/(TC + 278._rkind)) / (TC + 868._rkind)**2  ! SVP in Pa

! Compute derivative dSVP_dT analytically
dSVP_dT = SVP * ( &
        6545.8_rkind / (TC + 278._rkind)**2 &
        - 2._rkind / (TC + 868._rkind) )

if(testDeriv) print*, 'dSVP_dT check... ', SVP, dSVP_dT, (SATVPRESSICE(TC+dx) - SVP)/dx


END SUBROUTINE satVapPressIce




! ***************************************************************************************************************
! private function MSLP2AIRP: compute air pressure using mean sea level pressure and elevation
! ***************************************************************************************************************
! (after Shuttleworth, 1993)
!
! -- actually returns MSLP2AIRP in the same units as MSLP, because
!    ( (293.-0.0065*ELEV) / 293. )**5.256 is dimensionless
!
! ***************************************************************************************************************
FUNCTION MSLP2AIRP(MSLP, ELEV)
IMPLICIT NONE

real(rkind), INTENT(IN)         :: MSLP      ! base pressure (Pa)
real(rkind), INTENT(IN)         :: ELEV      ! elevation difference from base (m)

real(rkind)                     :: MSLP2AIRP ! Air pressure (Pa)

MSLP2AIRP = MSLP * ( (293.-0.0065*ELEV) / 293. )**5.256

END FUNCTION MSLP2AIRP


! ***************************************************************************************************************
! private function RLHUM2DEWPT: compute dewpoint temperature from relative humidity
! ***************************************************************************************************************
! ---- This is done with respect to water ONLY ----
!
! All units are SI standard - i.e. Kelvin and pascals
! Based on Tetens' formula (1930)
! ***************************************************************************************************************
FUNCTION RLHUM2DEWPT(T, RLHUM)
! Compute Dewpoint temperature from Relative Humidity
IMPLICIT NONE

real(rkind), INTENT(IN)         :: T         ! Temperature           (K)
real(rkind), INTENT(IN)         :: RLHUM     ! Relative Humidity     (%)


real(rkind)                     :: RLHUM2DEWPT     ! Dewpoint Temp   (K)

real(rkind)                     :: VPSAT     ! Sat. vapour pressure at T (Pa)
real(rkind)                     :: TDCEL     ! Dewpoint temp Celcius (C)

! Units note :              Pa = N m-2 = kg m-1 s-2
! SATVPFRZ=     610.8       ! Saturation water vapour pressure at 273.16K (Pa)
! W_RATIO =       0.622     ! molecular weight ratio of water to dry air (-)

VPSAT = SATVPFRZ * EXP( (17.27*(T-TFREEZE)) / (237.30 + (T-TFREEZE)) ) ! sat vapor press at grid cell (Pa)
TDCEL = 237.30 * LOG( (VPSAT/SATVPFRZ)*(RLHUM/100.) ) / &              ! dewpoint temperature         (C)
        (17.27 - LOG( (VPSAT/SATVPFRZ)*(RLHUM/100.) ) )
RLHUM2DEWPT = TDCEL + TFREEZE

END FUNCTION RLHUM2DEWPT


! ***************************************************************************************************************
! private function DEWPT2RLHUM: compute relative humidity from dewpoint temperature
! ***************************************************************************************************************
! ---- This is done with respect to water ONLY ----
!
! All units are SI standard - i.e. Kelvin and pascals
! Based on Tetens' formula (1930)
! ***************************************************************************************************************
FUNCTION DEWPT2RLHUM(T, DEWPT)
IMPLICIT NONE

real(rkind), INTENT(IN)         :: T         ! Temperature           (K)
real(rkind), INTENT(IN)         :: DEWPT     ! Dewpoint temp         (K)

real(rkind)                     :: DEWPT2RLHUM ! Relative Humidity   (%)

real(rkind)                     :: VPSAT     ! Sat. vapour pressure at T (Pa)
real(rkind)                     :: TDCEL     ! Dewpt in celcius      (C)

! Units note :              Pa = N m-2 = kg m-1 s-2
! SATVPFRZ=     610.8       ! Saturation water vapour pressure at 273.16K (Pa)

TDCEL = DEWPT-TFREEZE
VPSAT = SATVPFRZ * EXP( (17.27*(T-TFREEZE)) / (237.30 + (T-TFREEZE)) )      ! Sat vapor press (Pa)
DEWPT2RLHUM = 100. * (SATVPFRZ/VPSAT) * EXP((17.27*TDCEL)/(237.30+TDCEL))   ! Relative Humidity (%)

END FUNCTION DEWPT2RLHUM


! ***************************************************************************************************************
! private function DEWPT2SPHM: compute specific humidity from dewpoint temperature
! ***************************************************************************************************************
! ---- This is done with respect to water ONLY ----
!
! All units are SI standard - i.e. Kelvin and pascals
! Based on Tetens' formula (1930)
! VPAIR is the current vapor pressure as it used dewpoint to compute staurated VP
! ***************************************************************************************************************
FUNCTION DEWPT2SPHM(DEWPT, PRESS)
IMPLICIT NONE

real(rkind), INTENT(IN)         :: DEWPT     ! Dewpoint temp         (K)
real(rkind), INTENT(IN)         :: PRESS     ! Pressure              (Pa)

real(rkind)                     :: DEWPT2SPHM ! Specific Humidity    (g/g)

real(rkind)                     :: VPAIR     ! vapour pressure at T  (Pa)
real(rkind)                     :: TDCEL     ! Dewpt in celcius      (C)

! Units note :              Pa = N m-2 = kg m-1 s-2
! SATVPFRZ=     610.8       ! Saturation water vapour pressure at 273.16K (Pa)

TDCEL = DEWPT-TFREEZE
VPAIR = SATVPFRZ * EXP( (17.27*TDCEL) / (237.30 + TDCEL) )        ! Vapour Press           (Pa)
DEWPT2SPHM = (VPAIR * W_RATIO)/(PRESS - (1.-W_RATIO)*VPAIR)       ! Specific humidity (g/g)

END FUNCTION DEWPT2SPHM


! ***************************************************************************************************************
! private function DEWPT2VPAIR: compute vapor pressure of air from dewpoint temperature
! ***************************************************************************************************************
! ---- This is done with respect to water ONLY ----
!
! All units are SI standard - i.e. Kelvin and pascals
! Based on Tetens' formula (1930)
! VPAIR is the current vapor pressure as it used dewpoint to compute saturated VP
! ***************************************************************************************************************
FUNCTION DEWPT2VPAIR(DEWPT)
IMPLICIT NONE

real(rkind), INTENT(IN)         :: DEWPT     ! Dewpoint temp         (K)
real(rkind)                     :: TDCEL     ! Dewpt in celcius      (C)

real(rkind)                     :: DEWPT2VPAIR ! Vapour Press  (Pa)

! Units note :              Pa = N m-2 = kg m-1 s-2
! SATVPFRZ=     610.8       ! Saturation water vapour pressure at 273.16K (Pa)

TDCEL = DEWPT-TFREEZE
DEWPT2VPAIR = SATVPFRZ * EXP( (17.27*TDCEL) / (237.30 + TDCEL) )   ! Vapour Press  (Pa)

END FUNCTION DEWPT2VPAIR


! ***************************************************************************************************************
! public function SPHM2RELHM: compute relative humidity from specific humidity
! ***************************************************************************************************************
! ---- This is done with respect to water ONLY ----
!
! All units are SI standard - i.e. Kelvin and pascals
! Based on Tetens' formula (1930)
! ***************************************************************************************************************
FUNCTION SPHM2RELHM(SPHM, PRESS, TAIR)
IMPLICIT NONE

real(rkind), INTENT(IN)         :: SPHM      ! Specific Humidity (g/g)
real(rkind), INTENT(IN)         :: PRESS     ! Pressure              (Pa)
real(rkind), INTENT(IN)         :: TAIR      ! Air temp

real(rkind)                     :: SPHM2RELHM ! Dewpoint Temp (K)

real(rkind)                     :: VPSAT     ! vapour pressure at T  (Pa)
real(rkind)                     :: TDCEL     ! Dewpt in celcius      (C)
!real(rkind)                     :: DUM       ! Intermediate

! Units note :              Pa = N m-2 = kg m-1 s-2
! SATVPFRZ=     610.8       ! Saturation water vapour pressure at 273.16K (Pa)

TDCEL = TAIR-TFREEZE
VPSAT = SATVPFRZ * EXP( (17.27*TDCEL) / (237.30 + TDCEL) )       ! Vapour Press      (Pa)
SPHM2RELHM = (SPHM * PRESS)/(VPSAT * (W_RATIO + SPHM*(1.-W_RATIO)))

END FUNCTION SPHM2RELHM


! ***************************************************************************************************************
! public function RELHM2SPHM: compute specific humidity from relative humidity
! ***************************************************************************************************************
! ---- This is done with respect to water ONLY ----
!
! All units are SI standard - i.e. Kelvin and pascals
! Based on Tetens' formula (1930)
! ***************************************************************************************************************
FUNCTION RELHM2SPHM(RELHM, PRESS, TAIR)
IMPLICIT NONE

real(rkind), INTENT(IN)         :: RELHM     ! Relative Humidity     (%)
real(rkind), INTENT(IN)         :: PRESS     ! Pressure              (Pa)
real(rkind), INTENT(IN)         :: TAIR      ! Air temp

real(rkind)                     :: RELHM2SPHM ! Specific Humidity (g/g)

real(rkind)                     :: PVP       ! Partial vapour pressure at T  (Pa)
real(rkind)                     :: TDCEL     ! Dewpt in celcius      (C)
!real(rkind)                     :: DUM       ! Intermediate

! Units note :              Pa = N m-2 = kg m-1 s-2
! SATVPFRZ=     610.8       ! Saturation water vapour pressure at 273.16K (Pa)

TDCEL = TAIR-TFREEZE
PVP = RELHM * SATVPFRZ * EXP( (17.27*TDCEL)/(237.30 + TDCEL) ) ! Partial Vapour Press (Pa)
RELHM2SPHM = (PVP * W_RATIO)/(PRESS - (1. - W_RATIO)*PVP)

END FUNCTION RELHM2SPHM


! ***************************************************************************************************************
! public function WETBULBTMP: compute wet bulb temperature based on humidity and pressure
! ***************************************************************************************************************
FUNCTION WETBULBTMP(TAIR, RELHM, PRESS)
IMPLICIT NONE
! input
real(rkind), INTENT(IN)         :: TAIR      ! Air temp              (K)
real(rkind), INTENT(IN)         :: RELHM     ! Relative Humidity     (-)
real(rkind), INTENT(IN)         :: PRESS     ! Pressure              (Pa)
! output
real(rkind)                     :: WETBULBTMP ! Wet bulb temperature (K)
! locals
real(rkind)                     :: Tcel           ! Temperature in celcius      (C)
real(rkind)                     :: PVP            ! Partial vapor pressure (Pa)
real(rkind)                     :: TWcel          ! Wet bulb temperature in celcius (C)
real(rkind),PARAMETER           :: k=6.54E-4_DP   ! normalizing factor in wet bulb estimate (C-1)
real(rkind)                     :: Twet_trial0    ! trial value for wet bulb temperature (C)
real(rkind)                     :: Twet_trial1    ! trial value for wet bulb temperature (C)
real(rkind)                     :: f0,f1          ! function evaluations (C)
real(rkind)                     :: df_dT          ! derivative (-)
real(rkind)                     :: TWinc          ! wet bulb temperature increment (C)
INTEGER(I4B)                 :: iter           ! iterattion index
real(rkind),PARAMETER           :: Xoff=1.E-5_DP  ! finite difference increment (C)
real(rkind),PARAMETER           :: Xtol=1.E-8_DP  ! convergence tolerance (C)
INTEGER(I4B)                 :: maxiter=15     ! maximum number of iterations
! convert temperature to Celcius
Tcel = TAIR-TFREEZE
! compute partial vapor pressure based on temperature (Pa)
PVP = RELHM * SATVPRESS(Tcel)
! define an initial trial value for wetbulb temperature
TWcel = Tcel - 5._rkind
! iterate until convergence
do iter=1,maxiter
 ! compute Twet estimates
 Twet_trial0 = Tcel - (SATVPRESS(TWcel)      - PVP)/(k*PRESS)
 Twet_trial1 = Tcel - (SATVPRESS(TWcel+Xoff) - PVP)/(k*PRESS)
 ! compute function evaluations
 f0 = Twet_trial0 - TWcel
 f1 = Twet_trial1 - (TWcel+Xoff)
 ! compute derivative and iteration increment
 df_dT = (f0 - f1)/Xoff
 TWinc = f0/df_dT
 ! compute new value of wet bulb temperature (C)
 TWcel = TWcel + TWinc
 ! check if achieved tolerance
 if(abs(f0) < Xtol) exit
 ! check convergence
 if(iter==maxiter)stop 'failed to converge in WETBULBTMP'
end do  ! (iterating)

! return value in K
WETBULBTMP = TWcel + TFREEZE

END FUNCTION WETBULBTMP


! ***************************************************************************************************************
! private function SATVPRESS: compute saturated vapor pressure (Pa)
! ***************************************************************************************************************
! Units note :              Pa = N m-2 = kg m-1 s-2
! SATVPFRZ=     610.8       ! Saturation water vapour pressure at 273.16K (Pa)
! ***************************************************************************************************************
FUNCTION SATVPRESS(TCEL)
IMPLICIT NONE
real(rkind),INTENT(IN) :: TCEL      ! Temperature (C)
real(rkind)            :: SATVPRESS ! Saturated vapor pressure (Pa)
SATVPRESS = SATVPFRZ * EXP( (17.27_rkind*TCEL)/(237.30_rkind + TCEL) ) ! Saturated Vapour Press (Pa)
END FUNCTION SATVPRESS


FUNCTION SATVPRESSICE(TCEL)
IMPLICIT NONE
real(rkind),INTENT(IN) :: TCEL      ! Temperature (C)
real(rkind)            :: SATVPRESS ! Saturated vapor pressure (Pa)
!SATVPRESS = SATVPFRZ * EXP( (17.27_rkind*TCEL)/(237.30_rkind + TCEL) ) ! Saturated Vapour Press (Pa)
SATVPRESS = 1000._rkind * EXP(43.494_rkind - 6545.8_rkind/(TCEL + 278._rkind)) / (TCEL + 868._rkind)**2  ! SVP in Pa
END FUNCTION SATVPRESSICE


end module conv_funcs_module
