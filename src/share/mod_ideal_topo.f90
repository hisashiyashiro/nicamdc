!-------------------------------------------------------------------------------
module mod_ideal_topo
  !-----------------------------------------------------------------------------
  !
  !++ Description:
  !       This module is for the Dyn Core Test Initialization.
  !
  !
  !++ Current Corresponding Author : R.Yoshida
  !
  !++ History:
  !      Version   Date       Comment
  !      -----------------------------------------------------------------------
  !      0.00      12-10-19   Imported from mod_restart.f90 of NICAM
  !      0.01      13-06-12   Test cases in DCMIP2012 were imported
  !      0.02      14-01-28   Test case in Tomita and Satoh 2004 was imported
  !
  !      -----------------------------------------------------------------------
  !
  !-----------------------------------------------------------------------------
  !
  !++ Used modules
  !
  use mod_precision
  use mod_debug
  use mod_adm, only: &
     ADM_LOG_FID,  &
     ADM_NSYS
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: IDEAL_topo
  public :: IDEAL_topo_DP

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private procedures
  !
  private :: IDEAL_topo_JW
  private :: IDEAL_topo_Schar_Moderate
  private :: IDEAL_topo_Schar_Steep

  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  subroutine IDEAL_topo( &
       lat, &
       lon, &
       Zsfc )
    use mod_adm, only: &
       ADM_CTL_FID,   &
       ADM_proc_stop, &
       ADM_KNONE,     &
       ADM_gall,      &
       ADM_lall
    implicit none

    real(RP), intent(in)  :: lat (ADM_gall,ADM_KNONE,ADM_lall)
    real(RP), intent(in)  :: lon (ADM_gall,ADM_KNONE,ADM_lall)
    real(RP), intent(out) :: Zsfc(ADM_gall,ADM_KNONE,ADM_lall)

    character(len=ADM_NSYS) :: topo_type = ''

    namelist / IDEALTOPOPARAM / &
       topo_type

    integer :: ierr
    !---------------------------------------------------------------------------

    !--- read parameters
    write(ADM_LOG_FID,*)
    write(ADM_LOG_FID,*) '+++ Module[ideal topo]/Category[common share]'
    rewind(ADM_CTL_FID)
    read(ADM_CTL_FID,nml=IDEALTOPOPARAM,iostat=ierr)
    if ( ierr < 0 ) then
       write(ADM_LOG_FID,*) '*** IDEALTOPOPARAM is not specified. use default.'
    elseif( ierr > 0 ) then
       write(*,          *) 'xxx Not appropriate names in namelist IDEALTOPOPARAM. STOP.'
       write(ADM_LOG_FID,*) 'xxx Not appropriate names in namelist IDEALTOPOPARAM. STOP.'
       call ADM_proc_stop
    endif
    write(ADM_LOG_FID,nml=IDEALTOPOPARAM)

    if    ( topo_type == 'Schar_Moderate' ) then

       call IDEAL_topo_Schar_Moderate( lat (:,:,:), & !--- [IN]
                                       lon (:,:,:), & !--- [IN]
                                       Zsfc(:,:,:)  ) !--- [OUT]

    elseif( topo_type == 'Schar_Steep' ) then

       call IDEAL_topo_Schar_Steep( lat (:,:,:), & !--- [IN]
                                    lon (:,:,:), & !--- [IN]
                                    Zsfc(:,:,:)  ) !--- [OUT]

    elseif( topo_type == 'JW' ) then

       call IDEAL_topo_JW( lat (:,:,:), & !--- [IN]
                           lon (:,:,:), & !--- [IN]
                           Zsfc(:,:,:)  ) !--- [OUT]

    else
       write(*,          *) 'xxx Not appropriate topo_type. STOP.'
       write(ADM_LOG_FID,*) 'xxx Not appropriate topo_type. STOP.'
       call ADM_proc_stop
    endif

    return
  end subroutine IDEAL_topo

  subroutine IDEAL_topo_DP( &
       lat, &
       lon, &
       Zsfc )
    use mod_adm, only: &
       ADM_CTL_FID,   &
       ADM_proc_stop, &
       ADM_KNONE,     &
       ADM_gall,      &
       ADM_lall
    implicit none

    real(DP), intent(in)  :: lat (ADM_gall,ADM_KNONE,ADM_lall)
    real(DP), intent(in)  :: lon (ADM_gall,ADM_KNONE,ADM_lall)
    real(DP), intent(out) :: Zsfc(ADM_gall,ADM_KNONE,ADM_lall)

    character(len=ADM_NSYS) :: topo_type = ''

    namelist / IDEALTOPOPARAM / &
       topo_type

    integer :: ierr
    !---------------------------------------------------------------------------

    !--- read parameters
    write(ADM_LOG_FID,*)
    write(ADM_LOG_FID,*) '+++ Module[ideal topo]/Category[common share]'
    rewind(ADM_CTL_FID)
    read(ADM_CTL_FID,nml=IDEALTOPOPARAM,iostat=ierr)
    if ( ierr < 0 ) then
       write(ADM_LOG_FID,*) '*** IDEALTOPOPARAM is not specified. use default.'
    elseif( ierr > 0 ) then
       write(*,          *) 'xxx Not appropriate names in namelist IDEALTOPOPARAM. STOP.'
       write(ADM_LOG_FID,*) 'xxx Not appropriate names in namelist IDEALTOPOPARAM. STOP.'
       call ADM_proc_stop
    endif
    write(ADM_LOG_FID,nml=IDEALTOPOPARAM)

    if    ( topo_type == 'Schar_Moderate' ) then

       call IDEAL_topo_Schar_Moderate_DP( lat (:,:,:), & !--- [IN]
                                       lon (:,:,:), & !--- [IN]
                                       Zsfc(:,:,:)  ) !--- [OUT]

    elseif( topo_type == 'Schar_Steep' ) then

       call IDEAL_topo_Schar_Steep_DP( lat (:,:,:), & !--- [IN]
                                    lon (:,:,:), & !--- [IN]
                                    Zsfc(:,:,:)  ) !--- [OUT]

    elseif( topo_type == 'JW' ) then

       call IDEAL_topo_JW_DP( lat (:,:,:), & !--- [IN]
                           lon (:,:,:), & !--- [IN]
                           Zsfc(:,:,:)  ) !--- [OUT]

    else
       write(*,          *) 'xxx Not appropriate topo_type. STOP.'
       write(ADM_LOG_FID,*) 'xxx Not appropriate topo_type. STOP.'
       call ADM_proc_stop
    endif

    return
  end subroutine IDEAL_topo_DP

  !-----------------------------------------------------------------------------
  !> Moderately-steep Schar-like circular mountain (Ref.: DCMIP 2012 eq.(48))
  subroutine IDEAL_topo_Schar_Moderate( &
       lat, &
       lon, &
       Zsfc )
    use mod_adm, only: &
       ADM_CTL_FID,   &
       ADM_proc_stop, &
       ADM_KNONE,     &
       ADM_lall,      &
       ADM_gall
    use mod_cnst, only: &
       PI     => CNST_PI, &
       D2R    => CNST_D2R
    implicit none

    real(RP), intent(in)  :: lat (ADM_gall,ADM_KNONE,ADM_lall)
    real(RP), intent(in)  :: lon (ADM_gall,ADM_KNONE,ADM_lall)
    real(RP), intent(out) :: Zsfc(ADM_gall,ADM_KNONE,ADM_lall)

    real(RP) :: center_lon =  270.0_RP ! Longitude of Schar-type mountain center point [deg]
    real(RP) :: center_lat =    0.0_RP ! Latitude  of Schar-type mountain center point [deg]
    real(RP) :: H0         = 2000.0_RP ! Maximum Schar-type mountain height [m]
    real(RP) :: Rm_deg     =  135.0_RP ! Schar-type mountain radius     [deg]
    real(RP) :: QSIm_deg   =  11.25_RP ! Schar-type mountain wavelength [deg]

    namelist / IDEALTOPOPARAM_Schar_Moderate / &
       center_lon, &
       center_lat, &
       H0,         &
       Rm_deg,     &
       QSIm_deg

    real(RP) :: LAMBDA,  PHI
    real(RP) :: LAMBDAm, PHIm, Rm, QSIm
    real(RP) :: sinPHIm, cosPHIm
    real(RP) :: distance, mask

    integer :: g, l, K0
    integer :: ierr
    !---------------------------------------------------------------------------

    !--- read parameters
    write(ADM_LOG_FID,*)
    write(ADM_LOG_FID,*) '+++ Module[topo Schar Moderate]/Category[common share]'
    rewind(ADM_CTL_FID)
    read(ADM_CTL_FID,nml=IDEALTOPOPARAM_Schar_Moderate,iostat=ierr)
    if ( ierr < 0 ) then
       write(ADM_LOG_FID,*) '*** IDEALTOPOPARAM_Schar_Moderate is not specified. use default.'
    elseif( ierr > 0 ) then
       write(*,          *) 'xxx Not appropriate names in namelist IDEALTOPOPARAM_Schar_Moderate. STOP.'
       write(ADM_LOG_FID,*) 'xxx Not appropriate names in namelist IDEALTOPOPARAM_Schar_Moderate. STOP.'
       call ADM_proc_stop
    endif
    write(ADM_LOG_FID,nml=IDEALTOPOPARAM_Schar_Moderate)

    K0 = ADM_KNONE

    LAMBDAm = center_lon * D2R ! [deg]->[rad]
    PHIm    = center_lat * D2R ! [deg]->[rad]
    Rm      = Rm_deg     * D2R ! [deg]->[rad]
    QSIm    = QSIm_deg   * D2R ! [deg]->[rad]
    sinPHIm = sin(PHIm)
    cosPHIm = cos(PHIm)

    do l = 1, ADM_lall
    do g = 1, ADM_gall
       LAMBDA = lon(g,K0,l)
       PHI    = lat(g,K0,l)

       distance = acos( sinPHIm * sin(PHI)                       &
                      + cosPHIm * cos(PHI) * cos(LAMBDA-LAMBDAm) )

       mask = 0.5_RP - sign(0.5_RP,distance-Rm) ! if distance > Rm, mask = 0

       Zsfc(g,ADM_KNONE,l) = H0/2.0_RP                              &
                           * ( 1.0_RP + cos( PI * distance / Rm ) ) &
                           * cos( PI * distance / QSIm )**2         &
                           * mask
    enddo
    enddo

    return
  end subroutine IDEAL_topo_Schar_Moderate

  subroutine IDEAL_topo_Schar_Moderate_DP( &
       lat, &
       lon, &
       Zsfc )
    use mod_adm, only: &
       ADM_CTL_FID,   &
       ADM_proc_stop, &
       ADM_KNONE,     &
       ADM_lall,      &
       ADM_gall
    use mod_cnst, only: &
       PI     => CNST_PI, &
       D2R    => CNST_D2R
    implicit none

    real(DP), intent(in)  :: lat (ADM_gall,ADM_KNONE,ADM_lall)
    real(DP), intent(in)  :: lon (ADM_gall,ADM_KNONE,ADM_lall)
    real(DP), intent(out) :: Zsfc(ADM_gall,ADM_KNONE,ADM_lall)

    real(DP) :: center_lon =  270.0_DP ! Longitude of Schar-type mountain center point [deg]
    real(DP) :: center_lat =    0.0_DP ! Latitude  of Schar-type mountain center point [deg]
    real(DP) :: H0         = 2000.0_DP ! Maximum Schar-type mountain height [m]
    real(DP) :: Rm_deg     =  135.0_DP ! Schar-type mountain radius     [deg]
    real(DP) :: QSIm_deg   = 11.25_DP ! Schar-type mountain wavelength [deg]

    namelist / IDEALTOPOPARAM_Schar_Moderate / &
       center_lon, &
       center_lat, &
       H0,         &
       Rm_deg,     &
       QSIm_deg

    real(DP) :: LAMBDA,  PHI
    real(DP) :: LAMBDAm, PHIm, Rm, QSIm
    real(DP) :: sinPHIm, cosPHIm
    real(DP) :: distance, mask

    integer :: g, l, K0
    integer :: ierr
    !---------------------------------------------------------------------------

    !--- read parameters
    write(ADM_LOG_FID,*)
    write(ADM_LOG_FID,*) '+++ Module[topo Schar Moderate]/Category[common share]'
    rewind(ADM_CTL_FID)
    read(ADM_CTL_FID,nml=IDEALTOPOPARAM_Schar_Moderate,iostat=ierr)
    if ( ierr < 0 ) then
       write(ADM_LOG_FID,*) '*** IDEALTOPOPARAM_Schar_Moderate is not specified. use default.'
    elseif( ierr > 0 ) then
       write(*,          *) 'xxx Not appropriate names in namelist IDEALTOPOPARAM_Schar_Moderate. STOP.'
       write(ADM_LOG_FID,*) 'xxx Not appropriate names in namelist IDEALTOPOPARAM_Schar_Moderate. STOP.'
       call ADM_proc_stop
    endif
    write(ADM_LOG_FID,nml=IDEALTOPOPARAM_Schar_Moderate)

    K0 = ADM_KNONE

    LAMBDAm = center_lon * D2R ! [deg]->[rad]
    PHIm    = center_lat * D2R ! [deg]->[rad]
    Rm      = Rm_deg     * D2R ! [deg]->[rad]
    QSIm    = QSIm_deg   * D2R ! [deg]->[rad]
    sinPHIm = sin(PHIm)
    cosPHIm = cos(PHIm)

    do l = 1, ADM_lall
    do g = 1, ADM_gall
       LAMBDA = lon(g,K0,l)
       PHI    = lat(g,K0,l)

       distance = acos( sinPHIm * sin(PHI)                       &
                      + cosPHIm * cos(PHI) * cos(LAMBDA-LAMBDAm) )

       mask = 0.5_DP - sign(0.5_DP,distance-Rm) ! if distance > Rm, mask = 0

       Zsfc(g,ADM_KNONE,l) = H0/2.0_DP                              &
                           * ( 1.0_DP + cos( PI * distance / Rm ) ) &
                           * cos( PI * distance / QSIm )**2       &
                           * mask
    enddo
    enddo

    return
  end subroutine IDEAL_topo_Schar_Moderate_DP

  !-----------------------------------------------------------------------------
  !> Steep Schar-type mountain (Ref.: DCMIP 2012 eq.(76))
  subroutine IDEAL_topo_Schar_Steep( &
       lat, &
       lon, &
       Zsfc )
    use mod_adm, only: &
       ADM_CTL_FID,   &
       ADM_proc_stop, &
       ADM_KNONE,     &
       ADM_lall,      &
       ADM_gall
    use mod_cnst, only: &
       PI     => CNST_PI,      &
       D2R    => CNST_D2R,     &
       RADIUS => CNST_ERADIUS
    implicit none

    real(RP), intent(in)  :: lat (ADM_gall,ADM_KNONE,ADM_lall)
    real(RP), intent(in)  :: lon (ADM_gall,ADM_KNONE,ADM_lall)
    real(RP), intent(out) :: Zsfc(ADM_gall,ADM_KNONE,ADM_lall)

    real(RP) :: center_lon =   45.0_RP ! Longitude of Schar-type mountain center point [deg]
    real(RP) :: center_lat =    0.0_RP ! Latitude  of Schar-type mountain center point [deg]
    real(RP) :: H0         =  250.0_RP ! Maximum Schar-type mountain height [m]
    real(RP) :: d          = 5000.0_RP ! Schar-type mountain half-width [m]
    real(RP) :: QSI        = 4000.0_RP ! Schar-type mountain wavelength [m]

    namelist / IDEALTOPOPARAM_Schar_Steep / &
       center_lon, &
       center_lat, &
       H0,         &
       d,          &
       QSI

    real(RP) :: LAMBDA,  PHI
    real(RP) :: LAMBDAc, PHIc
    real(RP) :: sinPHIc, cosPHIc
    real(RP) :: distance

    integer :: g, l, K0
    integer :: ierr
    !---------------------------------------------------------------------------

    !--- read parameters
    write(ADM_LOG_FID,*)
    write(ADM_LOG_FID,*) '+++ Module[topo Schar Steep]/Category[common share]'
    rewind(ADM_CTL_FID)
    read(ADM_CTL_FID,nml=IDEALTOPOPARAM_Schar_Steep,iostat=ierr)
    if ( ierr < 0 ) then
       write(ADM_LOG_FID,*) '*** IDEALTOPOPARAM_Schar_Steep is not specified. use default.'
    elseif( ierr > 0 ) then
       write(*,          *) 'xxx Not appropriate names in namelist IDEALTOPOPARAM_Schar_Steep. STOP.'
       write(ADM_LOG_FID,*) 'xxx Not appropriate names in namelist IDEALTOPOPARAM_Schar_Steep. STOP.'
       call ADM_proc_stop
    endif
    write(ADM_LOG_FID,nml=IDEALTOPOPARAM_Schar_Steep)

    K0 = ADM_KNONE

    LAMBDAc = center_lon * D2R ! [deg]->[rad]
    PHIc    = center_lat * D2R ! [deg]->[rad]
    sinPHIc = sin(PHIc)
    cosPHIc = cos(PHIc)

    do l = 1, ADM_lall
    do g = 1, ADM_gall
       LAMBDA = lon(g,K0,l)
       PHI    = lat(g,K0,l)

       distance = RADIUS * acos( sinPHIc * sin(PHI)                       &
                               + cosPHIc * cos(PHI) * cos(LAMBDA-LAMBDAc) )

       Zsfc(g,ADM_KNONE,l) = H0                                  &
                           * exp( -(distance*distance) / (d*d) ) &
                           * cos( PI * distance / QSI )**2
    enddo
    enddo

    return
  end subroutine IDEAL_topo_Schar_Steep

  subroutine IDEAL_topo_Schar_Steep_DP( &
       lat, &
       lon, &
       Zsfc )
    use mod_adm, only: &
       ADM_CTL_FID,   &
       ADM_proc_stop, &
       ADM_KNONE,     &
       ADM_lall,      &
       ADM_gall
    use mod_cnst, only: &
       PI     => CNST_PI,      &
       D2R    => CNST_D2R,     &
       RADIUS => CNST_ERADIUS
    implicit none

    real(DP), intent(in)  :: lat (ADM_gall,ADM_KNONE,ADM_lall)
    real(DP), intent(in)  :: lon (ADM_gall,ADM_KNONE,ADM_lall)
    real(DP), intent(out) :: Zsfc(ADM_gall,ADM_KNONE,ADM_lall)

    real(DP) :: center_lon =   45.0_DP ! Longitude of Schar-type mountain center point [deg]
    real(DP) :: center_lat =    0.0_DP ! Latitude  of Schar-type mountain center point [deg]
    real(DP) :: H0         =  250.0_DP ! Maximum Schar-type mountain height [m]
    real(DP) :: d          = 5000.0_DP ! Schar-type mountain half-width [m]
    real(DP) :: QSI        = 4000.0_DP ! Schar-type mountain wavelength [m]

    namelist / IDEALTOPOPARAM_Schar_Steep / &
       center_lon, &
       center_lat, &
       H0,         &
       d,          &
       QSI

    real(DP) :: LAMBDA,  PHI
    real(DP) :: LAMBDAc, PHIc
    real(DP) :: sinPHIc, cosPHIc
    real(DP) :: distance

    integer :: g, l, K0
    integer :: ierr
    !---------------------------------------------------------------------------

    !--- read parameters
    write(ADM_LOG_FID,*)
    write(ADM_LOG_FID,*) '+++ Module[topo Schar Steep]/Category[common share]'
    rewind(ADM_CTL_FID)
    read(ADM_CTL_FID,nml=IDEALTOPOPARAM_Schar_Steep,iostat=ierr)
    if ( ierr < 0 ) then
       write(ADM_LOG_FID,*) '*** IDEALTOPOPARAM_Schar_Steep is not specified. use default.'
    elseif( ierr > 0 ) then
       write(*,          *) 'xxx Not appropriate names in namelist IDEALTOPOPARAM_Schar_Steep. STOP.'
       write(ADM_LOG_FID,*) 'xxx Not appropriate names in namelist IDEALTOPOPARAM_Schar_Steep. STOP.'
       call ADM_proc_stop
    endif
    write(ADM_LOG_FID,nml=IDEALTOPOPARAM_Schar_Steep)

    K0 = ADM_KNONE

    LAMBDAc = center_lon * D2R ! [deg]->[rad]
    PHIc    = center_lat * D2R ! [deg]->[rad]
    sinPHIc = sin(PHIc)
    cosPHIc = cos(PHIc)

    do l = 1, ADM_lall
    do g = 1, ADM_gall
       LAMBDA = lon(g,K0,l)
       PHI    = lat(g,K0,l)

       distance = RADIUS * acos( sinPHIc * sin(PHI)                       &
                               + cosPHIc * cos(PHI) * cos(LAMBDA-LAMBDAc) )

       Zsfc(g,ADM_KNONE,l) = H0                                  &
                           * exp( -(distance*distance) / (d*d) ) &
                           * cos( PI * distance / QSI )**2
    enddo
    enddo

    return
  end subroutine IDEAL_topo_Schar_Steep_DP

  !-----------------------------------------------------------------------------
  !> mountain for JW06 testcase
  subroutine IDEAL_topo_JW( &
       lat, &
       lon, &
       Zsfc )
    use mod_adm, only: &
       ADM_KNONE, &
       ADM_lall,  &
       ADM_gall
    use mod_cnst, only: &
       PI     => CNST_PI,      &
       RADIUS => CNST_ERADIUS, &
       OHM    => CNST_EOHM,    &
       GRAV   => CNST_EGRAV
    implicit none

    real(RP), intent(in)  :: lat (ADM_gall,ADM_KNONE,ADM_lall)
    real(RP), intent(in)  :: lon (ADM_gall,ADM_KNONE,ADM_lall)
    real(RP), intent(out) :: Zsfc(ADM_gall,ADM_KNONE,ADM_lall)

    real(RP), parameter :: ETA0 = 0.252_RP ! Value of eta at a reference level (position of the jet)
    real(RP), parameter :: ETAs =   1.0_RP ! Value of eta at the surface
    real(RP), parameter :: u0   =  35.0_RP ! Maximum amplitude of the zonal wind

    real(RP) :: PHI, ETAv, u0cos32ETAv
    real(RP) :: f1, f2

    integer :: g, l, K0
    !---------------------------------------------------------------------------

    K0 = ADM_KNONE

    ETAv        = ( ETAs - ETA0 ) * PI/2.0_RP
    u0cos32ETAv = u0 * cos(ETAv)**(3.0_RP/2.0_RP)

    ! for globe
    do l = 1, ADM_lall
    do g = 1, ADM_gall
       PHI = lat(g,K0,l)

       f1 = -2.0_RP * sin(PHI)**6 * ( cos(PHI)**2 + 1.0_RP/3.0_RP ) + 10.0_RP/63.0_RP
       f2 = 8.0_RP/5.0_RP * cos(PHI)**3 * ( sin(PHI)**2 + 2.0_RP/3.0_RP ) - PI/4.0_RP

       Zsfc(g,k0,l) = u0cos32ETAv * ( u0cos32ETAv*f1 + RADIUS*OHM*f2 ) / GRAV
    enddo
    enddo

    return
  end subroutine IDEAL_topo_JW

  subroutine IDEAL_topo_JW_DP( &
       lat, &
       lon, &
       Zsfc )
    use mod_adm, only: &
       ADM_KNONE, &
       ADM_lall,  &
       ADM_gall
    use mod_cnst, only: &
       PI     => CNST_PI,      &
       RADIUS => CNST_ERADIUS, &
       OHM    => CNST_EOHM,    &
       GRAV   => CNST_EGRAV
    implicit none

    real(DP), intent(in)  :: lat (ADM_gall,ADM_KNONE,ADM_lall)
    real(DP), intent(in)  :: lon (ADM_gall,ADM_KNONE,ADM_lall)
    real(DP), intent(out) :: Zsfc(ADM_gall,ADM_KNONE,ADM_lall)

    real(DP), parameter :: ETA0 = 0.252_DP ! Value of eta at a reference level (position of the jet)
    real(DP), parameter :: ETAs =    1.0_DP ! Value of eta at the surface
    real(DP), parameter :: u0   =   35.0_DP ! Maximum amplitude of the zonal wind

    real(DP) :: PHI, ETAv, u0cos32ETAv
    real(DP) :: f1, f2

    integer :: g, l, K0
    !---------------------------------------------------------------------------

    K0 = ADM_KNONE

    ETAv        = ( ETAs - ETA0 ) * PI/2.0_DP
    u0cos32ETAv = u0 * cos(ETAv)**(3.0_DP/2.0_DP)

    ! for globe
    do l = 1, ADM_lall
    do g = 1, ADM_gall
       PHI = lat(g,K0,l)

       f1 = -2.0_DP * sin(PHI)**6 * ( cos(PHI)**2 + 1.0_DP/3.0_DP ) + 10.0_DP/63.0_DP
       f2 = 8.0_DP/5.0_DP * cos(PHI)**3 * ( sin(PHI)**2 + 2.0_DP/3.0_DP ) - PI/4.0_DP

       Zsfc(g,k0,l) = u0cos32ETAv * ( u0cos32ETAv*f1 + RADIUS*OHM*f2 ) / GRAV
    enddo
    enddo

    return
  end subroutine IDEAL_topo_JW_DP

end module mod_ideal_topo
