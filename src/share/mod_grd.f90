!-------------------------------------------------------------------------------
!>
!! Grid system module
!!
!! @par Description
!!         This module is for the management of the icosahedral grid system
!!
!! @author  H.Tomita
!!
!! @par History
!! @li      2004-02-17 (H.Tomita)  Imported from igdc-4.33
!! @li      2009-01-23 (H.Tomita)  extend the vertical grid method, introducing "hflat".
!! @li      2009-03-10 (H.Tomita)  1. add sub[GRD_gen_plgrid]
!!                                    ( This subroutine generates
!!                                      the pole grids from the regular region grids. )
!!                                 2. support direct access of grid file without pole data.
!!                                    sub[GRD_input_hgrid,GRD_output_hgrid].
!!                                 3. add 'da_access_hgrid' in the namelist.
!! @li      2009-03-10 (H.Tomita)  add error handling in GRD_input_hgrid.
!! @li      2009-05-27 (M.Hara)    1. bug fix of error handling in GRD_input_hgrid.
!!                                 2. remove "optional" declaration from
!!                                    da_access in GRD_input_hgrid and GRD_output_hgrid.
!! @li      2011-07-22 (T.Ohno)    add parameters
!!                                 1.GRD_grid_type 'ON_SPHERE' / 'ON_PLANE'
!!                                 2.hgrid_comm_flg
!!                                   the grid data should be communicated or not. ( default:.true. )
!!                                 3.triangle_size
!!                                   scale factor when GRD_grid_type is 'ON_PLANE'
!! @li      2011-09-03 (H.Yashiro) New I/O
!! @li      2012-05-25 (H.Yashiro) Avoid irregal ISEND/IRECV comm.
!! @li      2012-10-20 (R.Yoshida) Topography for Jablonowski test
!!
!<
module mod_grd
  !-----------------------------------------------------------------------------
  !
  !++ Used modules
  !
  use mpi
  use mod_precision
  use mod_debug
  use mod_adm, only: &
     ADM_LOG_FID, &
     ADM_NSYS,    &
     ADM_MAXFNAME
  use mod_adm, only: &
     ADM_TI,      &
     ADM_TJ,      &
     ADM_AI,      &
     ADM_AIJ,     &
     ADM_AJ,      &
     ADM_lall,    &
     ADM_lall_pl, &
     ADM_gall,    &
     ADM_gall_pl, &
     ADM_kall,    &
     ADM_KNONE,   &
     ADM_nxyz
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: GRD_setup
  public :: GRD_output_hgrid
  public :: GRD_input_hgrid
  public :: GRD_scaling
  public :: GRD_output_vgrid
  public :: GRD_input_vgrid
  public :: GRD_gen_plgrid

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !

  !------ Indentifiers for the directions in the Cartesian coordinate.
  integer, public, parameter :: GRD_XDIR = 1
  integer, public, parameter :: GRD_YDIR = 2
  integer, public, parameter :: GRD_ZDIR = 3

  !====== Horizontal Grid ======
  !<-----
  !------ Grid points ( X: CELL CENTER )
  !<-----
  !<-----         GRD_x(1:ADM_gall,       &   --- horizontal
  !<-----               1:ADM_KNONE,      &   --- vertical
  !<-----               1:ADM_lall,       &   --- local region
  !<-----               GRD_XDIR:GRD_ZDIR )   --- three components
  !<-----
  !<-----         GRD_x_pl(1:ADM_gall_pl,   & --- horizontal
  !<-----                  1:ADM_KNONE,     & --- vertical
  !<-----                  1:ADM_lall_pl,   & --- pole regions
  !<-----                  GRD_XDIR:GRD_ZDIR) --- three components
  !<-----          .___.
  !<-----         /     \
  !<-----        .   p   .
  !<-----         \ ___ /
  !<-----          '   '
  !<-----
  !------ Grid points ( Xt: CELL VERTEX )
  !<-----
  !<-----         GRD_xt(1:ADM_gall,       &   --- horizontal
  !<-----                1:ADM_KNONE,      &   --- vertical
  !<-----                1:ADM_lall,       &   --- local region
  !<-----                ADM_TI:ADM_TJ,    &   --- upper or lower triangle
  !<-----                GRD_XDIR:GRD_ZDIR )   --- three components
  !<-----
  !<-----         GRD_xt_pl(1:ADM_gall_pl,   & --- horizontal
  !<-----                  1:ADM_KNONE,      & --- vertical
  !<-----                  1:ADM_lall_pl,    & --- pole regions
  !<-----                  GRD_XDIR:GRD_ZDIR ) --- three components
  !<-----          p___p
  !<-----         /     \
  !<-----        p       p
  !<-----         \ ___ /
  !<-----          p   p
  !<-----
  !------ Grid points ( Xr: CELL ARC )
  !<-----
  !<-----         GRD_xr(1:ADM_gall,       &   --- horizontal
  !<-----                1:ADM_KNONE,      &   --- vertical
  !<-----                1:ADM_lall,       &   --- local region
  !<-----                ADM_TI:ADM_TJ,    &   --- upper / middle / lower arc
  !<-----                GRD_XDIR:GRD_ZDIR )   --- three components
  !<-----
  !<-----         GRD_xr_pl(1:ADM_gall_pl,   & --- horizontal
  !<-----                  1:ADM_KNONE,      & --- vertical
  !<-----                  1:ADM_lall_pl,    & --- pole regions
  !<-----                  GRD_XDIR:GRD_ZDIR ) --- three components
  !<-----          ._p_.
  !<-----         p     p
  !<-----        .       .
  !<-----         p _ _ p
  !<-----          ' p '
  !<-----

  real(DP), public              :: GRD_rscale ! scaling factor for the radius of the sphere

#ifdef _FIXEDINDEX_
  real(DP), public              :: GRD_x    (ADM_gall   ,ADM_KNONE,ADM_lall   ,              ADM_nxyz)
  real(DP), public              :: GRD_x_pl (ADM_gall_pl,ADM_KNONE,ADM_lall_pl,              ADM_nxyz)
  real(DP), public              :: GRD_xt   (ADM_gall   ,ADM_KNONE,ADM_lall   ,ADM_TI:ADM_TJ,ADM_nxyz)
  real(DP), public              :: GRD_xt_pl(ADM_gall_pl,ADM_KNONE,ADM_lall_pl,              ADM_nxyz)
  real(DP), public              :: GRD_xr   (ADM_gall   ,ADM_KNONE,ADM_lall   ,ADM_AI:ADM_AJ,ADM_nxyz)
  real(DP), public              :: GRD_xr_pl(ADM_gall_pl,ADM_KNONE,ADM_lall_pl,              ADM_nxyz)
#else
  real(DP), public, allocatable :: GRD_x    (:,:,:,:)
  real(DP), public, allocatable :: GRD_x_pl (:,:,:,:)
  real(DP), public, allocatable :: GRD_xt   (:,:,:,:,:)
  real(DP), public, allocatable :: GRD_xt_pl(:,:,:,:)
  real(DP), public, allocatable :: GRD_xr   (:,:,:,:,:)
  real(DP), public, allocatable :: GRD_xr_pl(:,:,:,:)
#endif



  !====== Topography ======
  integer, public, parameter   :: GRD_ZSFC = 1

#ifdef _FIXEDINDEX_
  real(DP), public              :: GRD_zs   (ADM_gall   ,ADM_KNONE,ADM_lall   ,GRD_ZSFC)
  real(DP), public              :: GRD_zs_pl(ADM_gall_pl,ADM_KNONE,ADM_lall_pl,GRD_ZSFC)
#else
  real(DP), public, allocatable :: GRD_zs   (:,:,:,:)
  real(DP), public, allocatable :: GRD_zs_pl(:,:,:,:)
#endif



  !====== Vertical Grid ======
  !<-----
  !------ z coordinate ( actual height )
  !<-----
  !<-----         GRD_vz(1:ADM_gall,  &
  !<-----                1:ADM_kall,  &
  !<-----                1:ADM_lall,  &
  !<-----                GRD_Z:GRD_ZH )
  !<-----
  !<-----         GRD_vz_pl(1:ADM_gall_pl, &
  !<-----                   1:ADM_kall,    &
  !<-----                   1:ADM_lall_pl, &
  !<-----                   GRD_Z:GRD_ZH   )
  !<-----

  integer, public, parameter   :: GRD_Z  = 1
  integer, public, parameter   :: GRD_ZH = 2

  real(DP), public              :: GRD_htop ! model top height [m]

#ifdef _FIXEDINDEX_
  real(DP), public              :: GRD_gz   (ADM_kall)
  real(DP), public              :: GRD_gzh  (ADM_kall)
  real(DP), public              :: GRD_dgz  (ADM_kall)
  real(DP), public              :: GRD_dgzh (ADM_kall)
  real(DP), public              :: GRD_rdgz (ADM_kall)
  real(DP), public              :: GRD_rdgzh(ADM_kall)

  real(DP), public              :: GRD_afac(ADM_kall)
  real(DP), public              :: GRD_bfac(ADM_kall)
  real(DP), public              :: GRD_cfac(ADM_kall)
  real(DP), public              :: GRD_dfac(ADM_kall)

  real(DP), public              :: GRD_vz   (ADM_gall   ,ADM_kall,ADM_lall   ,GRD_Z:GRD_ZH)
  real(DP), public              :: GRD_vz_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl,GRD_Z:GRD_ZH)
#else
  real(DP), public, allocatable :: GRD_gz   (:) ! gsi (z-star) coordinate
  real(DP), public, allocatable :: GRD_gzh  (:) ! gsi (z-star) coordinate at the half point
  real(DP), public, allocatable :: GRD_dgz  (:) ! d(gsi)
  real(DP), public, allocatable :: GRD_dgzh (:) ! d(gsi) at the half point
  real(DP), public, allocatable :: GRD_rdgz (:)
  real(DP), public, allocatable :: GRD_rdgzh(:)

  real(DP), public, allocatable :: GRD_afac (:) ! From the cell center value to the cell wall value
  real(DP), public, allocatable :: GRD_bfac (:) !    A(k-1/2) = ( afac(k) A(k) + bfac(k) * A(k-1) ) / 2
  real(DP), public, allocatable :: GRD_cfac (:) ! From the cell wall value to the cell center value
  real(DP), public, allocatable :: GRD_dfac (:) !    A(k) = ( cfac(k) A(k+1/2) + dfac(k) * A(k-1/2) ) / 2

  real(DP), public, allocatable :: GRD_vz   (:,:,:,:)
  real(DP), public, allocatable :: GRD_vz_pl(:,:,:,:)
#endif

  character(len=ADM_NSYS), public :: GRD_grid_type = 'ON_SPHERE' ! grid type [add] T.Ohno 110722
                                                   ! 'ON_PLANE'

  !-----------------------------------------------------------------------------
  !
  !++ Private procedure
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  character(len=ADM_NSYS),     private :: hgrid_io_mode   = 'LEGACY' ! [add] H.Yashiro 20110819
  character(len=ADM_NSYS),     private :: topo_io_mode    = 'LEGACY' ! [add] H.Yashiro 20110819
  character(len=ADM_MAXFNAME), private :: hgrid_fname     = ''       ! horizontal grid file
  character(len=ADM_MAXFNAME), private :: topo_fname      = ''       ! topography file

  character(len=ADM_MAXFNAME), private :: vgrid_fname     = ''       ! vertical grid file
  character(len=ADM_NSYS),     private :: vgrid_scheme    = 'LINEAR' ! vertical coordinate scheme
  real(DP),                     private :: h_efold         = 10000.0_DP ! e-folding height for hybrid vertical coordinate [m]
  real(DP),                     private :: hflat           =  -999.0_DP ! [m]
  logical,                     private :: output_vgrid    = .false.  ! output verical grid file?

  logical,                     private :: hgrid_comm_flg  = .true.   ! communicate GRD_x?          [add] T.Ohno 110722
  real(DP),                     private :: triangle_size   = 0.0_DP     ! length of sides of triangle [add] T.Ohno 110722

  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  !> Setup
  subroutine GRD_setup
    use mod_adm, only:  &
       ADM_CTL_FID,        &
       ADM_proc_stop,      &
       ADM_prc_me,         &
       ADM_prc_run_master, &
       ADM_have_pl,        &
       ADM_gmin,           &
       ADM_gmax,           &
       ADM_gslf_pl,        &
       ADM_kmin,           &
       ADM_kmax
    use mod_cnst, only: &
       CNST_ERADIUS, &
       CNST_UNDEF
    use mod_comm, only:  &
       COMM_data_transfer, &
       COMM_data_transfer_DP
    implicit none

    namelist / GRDPARAM / &
       GRD_grid_type,  &
       hgrid_io_mode,  &
       topo_io_mode,   &
       hgrid_fname,    &
       topo_fname,     &
       vgrid_fname,    &
       vgrid_scheme,   &
       h_efold,        &
       hflat,          &
       output_vgrid,   &
       hgrid_comm_flg, &
       triangle_size

    real(DP) :: htop
    integer :: nstart, nend
    integer :: kflat

    integer :: ierr
    integer :: n, k, l, k0
    !---------------------------------------------------------------------------

    K0 = ADM_KNONE

    !--- read parameters
    write(ADM_LOG_FID,*)
    write(ADM_LOG_FID,*) '+++ Module[grd]/Category[common share]'
    rewind(ADM_CTL_FID)
    read(ADM_CTL_FID,nml=GRDPARAM,iostat=ierr)
    if ( ierr < 0 ) then
       write(ADM_LOG_FID,*) '*** GRDPARAM is not specified. use default.'
    elseif( ierr > 0 ) then
       write(*,          *) 'xxx Not appropriate names in namelist GRDPARAM. STOP.'
       write(ADM_LOG_FID,*) 'xxx Not appropriate names in namelist GRDPARAM. STOP.'
       call ADM_proc_stop
    endif
    write(ADM_LOG_FID,nml=GRDPARAM)



    !---< horizontal grid >---
#ifndef _FIXEDINDEX_
    allocate( GRD_x    (ADM_gall   ,K0,ADM_lall   ,              ADM_nxyz) )
    allocate( GRD_x_pl (ADM_gall_pl,K0,ADM_lall_pl,              ADM_nxyz) )
    allocate( GRD_xt   (ADM_gall   ,K0,ADM_lall   ,ADM_TI:ADM_TJ,ADM_nxyz) )
    allocate( GRD_xt_pl(ADM_gall_pl,K0,ADM_lall_pl,              ADM_nxyz) )
    allocate( GRD_xr   (ADM_gall   ,K0,ADM_lall   ,ADM_AI:ADM_AJ,ADM_nxyz) )
    allocate( GRD_xr_pl(ADM_gall_pl,K0,ADM_lall_pl,              ADM_nxyz) )
#endif
    GRD_x    (:,:,:,:)   = CNST_UNDEF
    GRD_x_pl (:,:,:,:)   = CNST_UNDEF
    GRD_xt   (:,:,:,:,:) = CNST_UNDEF
    GRD_xt_pl(:,:,:,:)   = CNST_UNDEF
    GRD_xr   (:,:,:,:,:) = CNST_UNDEF
    GRD_xr_pl(:,:,:,:)   = CNST_UNDEF

    call GRD_input_hgrid( hgrid_fname,  & ![IN]
                          .true.,       & ![IN]
                          hgrid_io_mode ) ![IN]

    ! data transfer for GRD_x (note: do not communicate GRD_xt)
    if( hgrid_comm_flg ) call COMM_data_transfer_DP(GRD_x,GRD_x_pl) ! [mod] T.Ohno 110722

    ! scaling
    if ( trim(GRD_grid_type) == 'ON_PLANE' ) then
       call GRD_scaling(triangle_size)
    else
       call GRD_scaling(dble(CNST_ERADIUS))
    endif

    ! calc position of cell arc
    call GRD_makearc



    !---< surface height >---
#ifndef _FIXEDINDEX_
    allocate( GRD_zs   (ADM_gall,   K0,ADM_lall,   GRD_ZSFC) )
    allocate( GRD_zs_pl(ADM_gall_pl,K0,ADM_lall_pl,GRD_ZSFC) )
#endif
    GRD_zs   (:,:,:,:) = 0.0_DP
    GRD_zs_pl(:,:,:,:) = 0.0_DP

    call GRD_input_topograph(topo_fname)



    !---< vertical coordinate >---

    if ( ADM_kall /= ADM_KNONE ) then
#ifndef _FIXEDINDEX_
       allocate( GRD_gz   (ADM_kall) )
       allocate( GRD_gzh  (ADM_kall) )
       allocate( GRD_dgz  (ADM_kall) )
       allocate( GRD_dgzh (ADM_kall) )
       allocate( GRD_rdgz (ADM_kall) )
       allocate( GRD_rdgzh(ADM_kall) )

       allocate( GRD_afac (ADM_kall) )
       allocate( GRD_bfac (ADM_kall) )
       allocate( GRD_cfac (ADM_kall) )
       allocate( GRD_dfac (ADM_kall) )

       allocate( GRD_vz   (ADM_gall   ,ADM_kall,ADM_lall   ,GRD_Z:GRD_ZH) )
       allocate( GRD_vz_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl,GRD_Z:GRD_ZH) )
#endif

       call GRD_input_vgrid(vgrid_fname)

       ! calculation of grid intervals ( cell center )
       do k = ADM_kmin-1, ADM_kmax
          GRD_dgz(k) = GRD_gzh(k+1) - GRD_gzh(k)
       enddo
       GRD_dgz(ADM_kmax+1) = GRD_dgz(ADM_kmax)

       ! calculation of grid intervals ( cell wall )
       do k = ADM_kmin, ADM_kmax+1
          GRD_dgzh(k) = GRD_gz(k) - GRD_gz(k-1)
       enddo
       GRD_dgzh(ADM_kmin-1) = GRD_dgzh(ADM_kmin)

       do k = 1, ADM_kall
          GRD_rdgz (k) = 1.0_DP / grd_dgz (k)
          GRD_rdgzh(k) = 1.0_DP / grd_dgzh(k)
       enddo

       ! hight top
       GRD_htop = GRD_gzh(ADM_kmax+1) - GRD_gzh(ADM_kmin)

       !--- vertical interpolation factor
       do k = ADM_kmin, ADM_kmax+1
          GRD_afac(k) = 2.0_DP * ( GRD_gzh(k) - GRD_gz(k-1) ) &
                             / ( GRD_gz (k) - GRD_gz(k-1) )
       enddo
       GRD_afac(ADM_kmin-1) = 2.0_DP

       GRD_bfac(:) = 2.0_DP - GRD_afac(:)

       do k = ADM_kmin, ADM_kmax
          GRD_cfac(k) = 2.0_DP * ( GRD_gz (k  ) - GRD_gzh(k) ) &
                             / ( GRD_gzh(k+1) - GRD_gzh(k) )
       enddo
       GRD_cfac(ADM_kmin-1) = 2.0_DP
       GRD_cfac(ADM_kmax+1) = 0.0_DP

       GRD_dfac(:) = 2.0_DP - GRD_cfac(:)

       !--- setup z-coordinate
       nstart = suf(ADM_gmin,ADM_gmin)
       nend   = suf(ADM_gmax,ADM_gmax)

       select case(vgrid_scheme)
       case('LINEAR')

          ! linear transfromation : (Gal-Chen & Sommerville(1975)
          !    gz = H(z-zs)/(H-zs) -> z = (H-zs)/H * gz + zs

          kflat = -1
          if ( hflat > 0.0_DP ) then !--- default : -999.0
             do k = ADM_kmin+1, ADM_kmax+1
                if ( hflat < GRD_gzh(k) ) then
                   kflat = k
                   exit
                endif
             enddo
          endif

          if ( kflat == -1 ) then
             kflat = ADM_kmax + 1
             htop  = GRD_htop
          else
             htop  = GRD_gzh(kflat) - GRD_gzh(ADM_kmin)
          endif

          do l = 1, ADM_lall
             do k = ADM_kmin-1, kflat
             do n = nstart, nend
                GRD_vz(n,k,l,GRD_Z ) = GRD_zs(n,K0,l,GRD_ZSFC) &
                                     + ( htop - GRD_zs(n,K0,l,GRD_ZSFC) ) / htop * GRD_gz(k)
                GRD_vz(n,k,l,GRD_ZH) = GRD_zs(n,K0,l,GRD_ZSFC) &
                                     + ( htop - GRD_zs(n,K0,l,GRD_ZSFC) ) / htop * GRD_gzh(k)
             enddo
             enddo

             if ( kflat < ADM_kmax+1 ) then
                do k = kflat+1, ADM_kmax+1
                do n = nstart, nend
                   GRD_vz(n,k,l,GRD_Z ) = GRD_gz (k)
                   GRD_vz(n,k,l,GRD_ZH) = GRD_gzh(k)
                enddo
                enddo
             endif
          enddo

          if ( ADM_have_pl ) then
             n = ADM_GSLF_PL
             do l = 1, ADM_lall_pl
                do k = ADM_kmin-1, kflat
                   GRD_vz_pl(n,k,l,GRD_Z)  = GRD_zs_pl(n,K0,l,GRD_ZSFC) &
                                           + ( htop - GRD_zs_pl(n,K0,l,GRD_ZSFC) ) / htop * GRD_gz(k)
                   GRD_vz_pl(n,k,l,GRD_ZH) = GRD_zs_pl(n,K0,l,GRD_ZSFC) &
                                           + ( htop - GRD_zs_pl(n,K0,l,GRD_ZSFC) ) / htop * GRD_gzh(k)
                enddo

                if ( kflat < ADM_kmax+1 ) then
                   do k = kflat+1, ADM_kmax+1
                      GRD_vz_pl(n,k,l,GRD_Z ) = GRD_gz (k)
                      GRD_vz_pl(n,k,l,GRD_ZH) = GRD_gzh(k)
                   enddo
                endif
             enddo
          endif

       case('HYBRID')

          ! Hybrid transformation : like as Simmons & Buridge(1981)

          do l = 1, ADM_lall
          do k = ADM_kmin-1, ADM_kmax+1
          do n = nstart, nend
             GRD_vz(n,k,l,GRD_Z)  = GRD_gz(k)                               &
                                  + GRD_zs(n,K0,l,1)                        &
                                  * sinh( (GRD_htop-GRD_gz (k)) / h_efold ) &
                                  / sinh(  GRD_htop             / h_efold )
             GRD_vz(n,k,l,GRD_ZH) = GRD_gzh(k)                              &
                                  + GRD_zs(n,K0,l,1)                        &
                                  * sinh( (GRD_htop-GRD_gzh(k)) / h_efold ) &
                                  / sinh(  GRD_htop             / h_efold )
          enddo
          enddo
          enddo

          if ( ADM_have_pl ) then
             n = ADM_GSLF_PL
             do l = 1, ADM_lall_pl
             do k = ADM_kmin-1, ADM_kmax+1
                GRD_vz_pl(n,k,l,GRD_Z)  = GRD_gz(k)                               &
                                        + GRD_zs_pl(n,K0,l,1)                     &
                                        * sinh( (GRD_htop-GRD_gz (k)) / h_efold ) &
                                        / sinh(  GRD_htop             / h_efold )
                GRD_vz_pl(n,k,l,GRD_ZH) = GRD_gzh(k)                              &
                                        + GRD_zs_pl(n,K0,l,1)                     &
                                        * sinh( (GRD_htop-GRD_gzh(k)) / h_efold ) &
                                        / sinh(  GRD_htop             / h_efold )
             enddo
             enddo
          endif

       endselect

       !--- fill HALO
       call COMM_data_transfer_DP(GRD_vz,GRD_vz_pl)

       GRD_vz(suf(ADM_gmax+1,ADM_gmin-1),:,:,:) = GRD_vz(suf(ADM_gmax+1,ADM_gmin),:,:,:)
       GRD_vz(suf(ADM_gmin-1,ADM_gmax+1),:,:,:) = GRD_vz(suf(ADM_gmin,ADM_gmax+1),:,:,:)
    endif

    !--- output information about grid.
    if ( ADM_kall /= ADM_KNONE ) then
       write(ADM_LOG_FID,*)
       write(ADM_LOG_FID,'(5x,A)')             '|======      Vertical Coordinate [m]      ======|'
       write(ADM_LOG_FID,'(5x,A)')             '|                                               |'
       write(ADM_LOG_FID,'(5x,A)')             '|          -GRID CENTER-       -GRID INTERFACE- |'
       write(ADM_LOG_FID,'(5x,A)')             '|  k        gz     d(gz)      gzh    d(gzh)   k |'
       write(ADM_LOG_FID,'(5x,A)')             '|                                               |'
       k = ADM_kmax + 1
       write(ADM_LOG_FID,'(5x,A,I3,2F10.1,A)') '|',k,GRD_gz(k),GRD_dgz(k), '                        | dummy'
       write(ADM_LOG_FID,'(5x,A,2F10.1,I4,A)') '|                      ',GRD_gzh(k),GRD_dgzh(k),k,' | TOA'
       k = ADM_kmax
       write(ADM_LOG_FID,'(5x,A,I3,2F10.1,A)') '|',k,GRD_gz(k),GRD_dgz(k), '                        | kmax'
       write(ADM_LOG_FID,'(5x,A,2F10.1,I4,A)') '|                      ',GRD_gzh(k),GRD_dgzh(k),k,' |'
       do k = ADM_kmax-1, ADM_kmin+1, -1
       write(ADM_LOG_FID,'(5x,A,I3,2F10.1,A)') '|',k,GRD_gz(k),GRD_dgz(k), '                        |'
       write(ADM_LOG_FID,'(5x,A,2F10.1,I4,A)') '|                      ',GRD_gzh(k),GRD_dgzh(k),k,' |'
       enddo
       k = ADM_kmin
       write(ADM_LOG_FID,'(5x,A,I3,2F10.1,A)') '|',k,GRD_gz(k),GRD_dgz(k), '                        | kmin'
       write(ADM_LOG_FID,'(5x,A,2F10.1,I4,A)') '|                      ',GRD_gzh(k),GRD_dgzh(k),k,' | ground'
       k = ADM_kmin-1
       write(ADM_LOG_FID,'(5x,A,I3,2F10.1,A)') '|',k,GRD_gz(k),GRD_dgz(k), '                        | dummy'
       write(ADM_LOG_FID,'(5x,A)')             '|===============================================|'

       write(ADM_LOG_FID,*)
       write(ADM_LOG_FID,*) '--- Vertical layer scheme = ', trim(vgrid_scheme)
       if ( vgrid_scheme == 'HYBRID' ) then
          write(ADM_LOG_FID,*) '--- e-folding height = ', h_efold
       endif

       if ( output_vgrid ) then
          if ( ADM_prc_me == ADM_prc_run_master ) then
             call GRD_output_vgrid('./vgrid_used.dat')
          endif
       endif
    else
       write(ADM_LOG_FID,*)
       write(ADM_LOG_FID,*) '--- vartical layer = 1'
    endif

    return
  end subroutine GRD_setup

  !-----------------------------------------------------------------------------
  !> Input horizontal grid
  subroutine GRD_input_hgrid( &
       basename,     &
       input_vertex, &
       io_mode       )
    use mod_misc, only: &
       MISC_make_idstr,       &
       MISC_get_available_fid
    use mod_adm, only: &
       ADM_proc_stop, &
       ADM_prc_tab,   &
       ADM_prc_me
    use mod_fio, only: &
       FIO_input_DP
    implicit none

    character(len=*), intent(in) :: basename     ! input basename
    logical,          intent(in) :: input_vertex ! flag of B-grid input
    character(len=*), intent(in) :: io_mode      ! io_mode

    character(len=ADM_MAXFNAME) :: fname

    integer :: fid, ierr
    integer :: rgnid, l, K0
    !---------------------------------------------------------------------------

    K0 = ADM_KNONE

    if ( io_mode == 'ADVANCED' ) then

       call FIO_input_DP(GRD_x(:,:,:,GRD_XDIR),basename,'grd_x_x','ZSSFC1',K0,K0,1)
       call FIO_input_DP(GRD_x(:,:,:,GRD_YDIR),basename,'grd_x_y','ZSSFC1',K0,K0,1)
       call FIO_input_DP(GRD_x(:,:,:,GRD_ZDIR),basename,'grd_x_z','ZSSFC1',K0,K0,1)
       if ( input_vertex ) then
          call FIO_input_DP(GRD_xt(:,:,:,ADM_TI,GRD_XDIR),basename, &
                         'grd_xt_ix','ZSSFC1',K0,K0,1            )
          call FIO_input_DP(GRD_xt(:,:,:,ADM_TJ,GRD_XDIR),basename, &
                         'grd_xt_jx','ZSSFC1',K0,K0,1            )
          call FIO_input_DP(GRD_xt(:,:,:,ADM_TI,GRD_YDIR),basename, &
                         'grd_xt_iy','ZSSFC1',K0,K0,1            )
          call FIO_input_DP(GRD_xt(:,:,:,ADM_TJ,GRD_YDIR),basename, &
                         'grd_xt_jy','ZSSFC1',K0,K0,1            )
          call FIO_input_DP(GRD_xt(:,:,:,ADM_TI,GRD_ZDIR),basename, &
                         'grd_xt_iz','ZSSFC1',K0,K0,1            )
          call FIO_input_DP(GRD_xt(:,:,:,ADM_TJ,GRD_ZDIR),basename, &
                         'grd_xt_jz','ZSSFC1',K0,K0,1            )
       endif

    elseif( io_mode == 'LEGACY' ) then

       do l = 1, ADM_lall
          rgnid = ADM_prc_tab(l,ADM_prc_me)
          call MISC_make_idstr(fname,trim(basename),'rgn',rgnid)

          fid = MISC_get_available_fid()
          open( unit   = fid,           &
                file   = trim(fname),   &
                form   = 'unformatted', &
                access = 'direct',      &
                recl   = ADM_gall*8,    &
                status = 'old',         &
                iostat = ierr           )

             if ( ierr /= 0 ) then
                write(ADM_LOG_FID,*) 'xxx Error occured in reading grid file.', trim(fname)
                call ADM_proc_stop
             endif

             read(fid,rec=1) GRD_x(:,K0,l,GRD_XDIR)
             read(fid,rec=2) GRD_x(:,K0,l,GRD_YDIR)
             read(fid,rec=3) GRD_x(:,K0,l,GRD_ZDIR)
             if ( input_vertex ) then
                read(fid,rec=4) GRD_xt(:,K0,l,ADM_TI,GRD_XDIR)
                read(fid,rec=5) GRD_xt(:,K0,l,ADM_TI,GRD_YDIR)
                read(fid,rec=6) GRD_xt(:,K0,l,ADM_TI,GRD_ZDIR)
                read(fid,rec=7) GRD_xt(:,K0,l,ADM_TJ,GRD_XDIR)
                read(fid,rec=8) GRD_xt(:,K0,l,ADM_TJ,GRD_YDIR)
                read(fid,rec=9) GRD_xt(:,K0,l,ADM_TJ,GRD_ZDIR)
             endif
          close(fid)
       enddo

    else
       write(ADM_LOG_FID,*) 'Invalid io_mode!'
       call ADM_proc_stop
    endif

    call GRD_gen_plgrid

    return
  end subroutine GRD_input_hgrid

  !-----------------------------------------------------------------------------
  !> Output horizontal grid
  subroutine GRD_output_hgrid( &
       basename,      &
       output_vertex, &
       io_mode        )
    use mod_misc, only: &
       MISC_make_idstr,&
       MISC_get_available_fid
    use mod_adm, only: &
       ADM_proc_stop, &
       ADM_prc_tab,   &
       ADM_prc_me
    use mod_fio, only: &
!       FIO_output, &
       FIO_output_DP, &
       FIO_HMID,   &
       FIO_REAL8
    implicit none

    character(len=*), intent(in) :: basename      ! output basename
    logical,          intent(in) :: output_vertex ! output flag of B-grid
    character(len=*), intent(in) :: io_mode       ! io_mode

    character(len=ADM_MAXFNAME) :: fname
    character(len=FIO_HMID)     :: desc = 'HORIZONTAL GRID FILE'

    integer :: fid
    integer :: rgnid, l, K0
    !---------------------------------------------------------------------------

    K0 = ADM_KNONE

    if ( io_mode == 'ADVANCED' ) then

       call FIO_output_DP( GRD_x(:,:,:,GRD_XDIR),                           &
                        basename, desc, "",                              &
                       "grd_x_x", "GRD_x (X_DIR)", "",                   &
                       "NIL", FIO_REAL8, "ZSSFC1", K0, K0, 1, 0.0_DP, 0.0_DP )
       call FIO_output_DP( GRD_x(:,:,:,GRD_YDIR),                           &
                        basename, desc, '',                              &
                       'grd_x_y', 'GRD_x (Y_DIR)', '',                   &
                       'NIL', FIO_REAL8, 'ZSSFC1', K0, K0, 1, 0.0_DP, 0.0_DP )
       call FIO_output_DP( GRD_x(:,:,:,GRD_ZDIR),                           &
                        basename, desc, '',                              &
                       'grd_x_z', 'GRD_x (Z_DIR)', '',                   &
                       'NIL', FIO_REAL8, 'ZSSFC1', K0, K0, 1, 0.0_DP, 0.0_DP )

       if ( output_vertex ) then
          call FIO_output_DP( GRD_xt(:,:,:,ADM_TI,GRD_XDIR),                   &
                           basename, desc, '',                              &
                          'grd_xt_ix', 'GRD_xt (TI,X_DIR)', '',             &
                          'NIL', FIO_REAL8, 'ZSSFC1', K0, K0, 1, 0.0_DP, 0.0_DP )
          call FIO_output_DP( GRD_xt(:,:,:,ADM_TJ,GRD_XDIR),                   &
                           basename, desc, '',                              &
                          'grd_xt_jx', 'GRD_xt (TJ,X_DIR)', '',             &
                          'NIL', FIO_REAL8, 'ZSSFC1', K0, K0, 1, 0.0_DP, 0.0_DP )
          call FIO_output_DP( GRD_xt(:,:,:,ADM_TI,GRD_YDIR),                   &
                           basename, desc, '',                              &
                          'grd_xt_iy', 'GRD_xt (TI,Y_DIR)', '',             &
                          'NIL', FIO_REAL8, 'ZSSFC1', K0, K0, 1, 0.0_DP, 0.0_DP )
          call FIO_output_DP( GRD_xt(:,:,:,ADM_TJ,GRD_YDIR),                   &
                           basename, desc, '',                              &
                          'grd_xt_jy', 'GRD_xt (TJ,Y_DIR)', '',             &
                          'NIL', FIO_REAL8, 'ZSSFC1', K0, K0, 1, 0.0_DP, 0.0_DP )
          call FIO_output_DP( GRD_xt(:,:,:,ADM_TI,GRD_ZDIR),                   &
                           basename, desc, '',                              &
                          'grd_xt_iz', 'GRD_xt (TI,Z_DIR)', '',             &
                          'NIL', FIO_REAL8, 'ZSSFC1', K0, K0, 1, 0.0_DP, 0.0_DP )
          call FIO_output_DP( GRD_xt(:,:,:,ADM_TJ,GRD_ZDIR),                   &
                           basename, desc, '',                              &
                          'grd_xt_jz', 'GRD_xt (TJ,Z_DIR)', '',             &
                          'NIL', FIO_REAL8, 'ZSSFC1', K0, K0, 1, 0.0_DP, 0.0_DP )
       endif

    elseif( io_mode == 'LEGACY' ) then

       do l = 1, ADM_lall
          rgnid = ADM_prc_tab(l,ADM_prc_me)
          call MISC_make_idstr(fname,trim(basename),'rgn',rgnid)

          fid = MISC_get_available_fid()
          open( unit = fid, &
               file=trim(fname),   &
               form='unformatted', &
               access='direct',    &
               recl=ADM_gall*8     )

             write(fid,rec=1) GRD_x(:,K0,l,GRD_XDIR)
             write(fid,rec=2) GRD_x(:,K0,l,GRD_YDIR)
             write(fid,rec=3) GRD_x(:,K0,l,GRD_ZDIR)
             if ( output_vertex ) then
                write(fid,rec=4) GRD_xt(:,K0,l,ADM_TI,GRD_XDIR)
                write(fid,rec=5) GRD_xt(:,K0,l,ADM_TI,GRD_YDIR)
                write(fid,rec=6) GRD_xt(:,K0,l,ADM_TI,GRD_ZDIR)
                write(fid,rec=7) GRD_xt(:,K0,l,ADM_TJ,GRD_XDIR)
                write(fid,rec=8) GRD_xt(:,K0,l,ADM_TJ,GRD_YDIR)
                write(fid,rec=9) GRD_xt(:,K0,l,ADM_TJ,GRD_ZDIR)
             endif
          close(fid)
       enddo
    else
       write(ADM_LOG_FID,*) 'Invalid io_mode!'
       call ADM_proc_stop
    endif

    return
  end subroutine GRD_output_hgrid

  !-----------------------------------------------------------------------------
  !> Input vertical grid
  subroutine GRD_input_vgrid( fname )
    use mod_misc, only: &
       MISC_get_available_fid
    use mod_adm, only: &
       ADM_proc_stop, &
       ADM_vlayer
    implicit none

    character(len=ADM_MAXFNAME), intent(in) :: fname ! vertical grid file name

    integer               :: num_of_layer
    real(DP), allocatable :: gz (:)
    real(DP), allocatable :: gzh(:)

    integer :: fid, ierr
    !---------------------------------------------------------------------------

    write(ADM_LOG_FID,*) '*** Read vertical grid file: ', trim(fname)

    fid = MISC_get_available_fid()
    open( unit   = fid,           &
          file   = trim(fname),   &
          status = 'old',         &
          form   = 'unformatted', &
          iostat = ierr           )

       if ( ierr /= 0 ) then
          write(ADM_LOG_FID,*) 'xxx No vertical grid file.'
          call ADM_proc_stop
       endif

       read(fid) num_of_layer

       allocate( gz (1+num_of_layer+1) )
       allocate( gzh(1+num_of_layer+1) )

       read(fid) gz (:)
       read(fid) gzh(:)

       if ( num_of_layer /= ADM_vlayer ) then
          write(ADM_LOG_FID,*) 'xxx inconsistency in number of vertical layers.'
          call ADM_proc_stop
       endif

       GRD_gz (:) = real(gz ,kind=DP)
       GRD_gzh(:) = real(gzh,kind=DP)

    close(fid)

    return
  end subroutine GRD_input_vgrid

  !-----------------------------------------------------------------------------
  !> Output vertical grid
  subroutine GRD_output_vgrid( fname )
    use mod_misc, only: &
       MISC_get_available_fid
    use mod_adm, only: &
       ADM_vlayer
    implicit none

    character(len=*), intent(in) :: fname

    integer :: fid
    !---------------------------------------------------------------------------

    fid = MISC_get_available_fid()
    open(fid,file=trim(fname),form='unformatted')
       write(fid) ADM_vlayer
       write(fid) GRD_gz
       write(fid) GRD_gzh
    close(fid)

    return
  end subroutine GRD_output_vgrid

  !-----------------------------------------------------------------------------
  !> Input topography data
  subroutine GRD_input_topograph( &
       basename )
    use mod_misc,  only: &
       MISC_make_idstr,        &
       MISC_get_available_fid, &
       MISC_get_latlon_DP
    use mod_adm, only: &
       ADM_prc_tab, &
       ADM_prc_me
    use mod_fio, only: &
       FIO_input_DP
    use mod_comm, only: &
       COMM_var_DP
    use mod_ideal_topo, only: &
       IDEAL_topo_DP
    implicit none

    character(len=*), intent(in) :: basename

    real(DP) :: lat(ADM_gall,ADM_KNONE,ADM_lall)
    real(DP) :: lon(ADM_gall,ADM_KNONE,ADM_lall)

    character(len=128) :: fname
    integer            :: g, l, rgnid
    integer            :: fid
    !---------------------------------------------------------------------------

    write(ADM_LOG_FID,*) '*** topography data input'

    if ( topo_io_mode == 'ADVANCED' ) then

       if ( basename /= 'NONE' ) then
          call FIO_input_DP(GRD_zs(:,:,:,GRD_ZSFC),basename,'topo','ZSSFC1',1,1,1)
       endif

    elseif( topo_io_mode == 'LEGACY' ) then

       if ( basename /= 'NONE' ) then
          do l = 1, ADM_lall
             rgnid = ADM_prc_tab(l,ADM_prc_me)
             call MISC_make_idstr(fname,trim(basename),'rgn',rgnid)
             fid = MISC_get_available_fid()

             open( fid,                    &
                   file   = trim(fname),   &
                   form   = 'unformatted', &
                   access = 'direct',      &
                   recl   = ADM_gall*8,    &
                   status = 'old'          )

                read(fid,rec=1) GRD_zs(:,ADM_KNONE,l,GRD_ZSFC)

             close(fid)
          enddo
       endif

    elseif( topo_io_mode == 'IDEAL' ) then

       write(ADM_LOG_FID,*) '*** make ideal topography'

       do l = 1, ADM_lall
       do g = 1, ADM_gall
          call MISC_get_latlon_DP( lat  (g,ADM_KNONE,l),          &
                                lon  (g,ADM_KNONE,l),          &
                                GRD_x(g,ADM_KNONE,l,GRD_XDIR), &
                                GRD_x(g,ADM_KNONE,l,GRD_YDIR), &
                                GRD_x(g,ADM_KNONE,l,GRD_ZDIR)  )
       enddo
       enddo

       call IDEAL_topo_DP( lat   (:,:,:),         & !--- [IN]
                        lon   (:,:,:),         & !--- [IN]
                        GRD_zs(:,:,:,GRD_ZSFC) ) !--- [OUT]

    endif !--- io_mode

    call COMM_var_DP( GRD_zs, GRD_zs_pl, ADM_KNONE, 1 )

    return
  end subroutine GRD_input_topograph

  !-----------------------------------------------------------------------------
  !> Communicate grid data for pole region: This routine is NOT same as COMM_var
  subroutine GRD_gen_plgrid
    use mod_adm, only: &
       ADM_proc_stop,  &
       ADM_rgn_nmax,   &
       ADM_rgn_vnum,   &
       ADM_rgn_vtab,   &
       ADM_rgn2prc,    &
       ADM_RID,        &
       ADM_VLINK_NMAX, &
       ADM_COMM_WORLD, &
       ADM_prc_tab,    &
       ADM_prc_me,     &
       ADM_prc_npl,    &
       ADM_prc_spl,    &
       ADM_N,          &
       ADM_S,          &
       ADM_NPL,        &
       ADM_SPL,        &
       ADM_gmax,       &
       ADM_gmin,       &
       ADM_gslf_pl
    use mod_comm, only: &
       COMM_var_DP
    implicit none

    integer :: prctab   (ADM_VLINK_NMAX)
    integer :: rgntab   (ADM_VLINK_NMAX)
    integer :: sreq     (ADM_VLINK_NMAX)
    integer :: rreq     (ADM_VLINK_NMAX)
    logical :: send_flag(ADM_VLINK_NMAX)

    real(DP) :: vsend_pl (ADM_nxyz,ADM_vlink_nmax)
    real(DP) :: vrecv_pl (ADM_nxyz,ADM_vlink_nmax)

    integer :: datatype

    integer :: istat(MPI_STATUS_SIZE)
    integer :: n, l, ierr
    !---------------------------------------------------------------------------

    if ( DP == DP ) then
       datatype = MPI_DOUBLE_PRECISION
    elseif( DP == SP ) then
       datatype = MPI_REAL
    else
       write(*,*) 'xxx precision is not supportd'
       call ADM_proc_stop
    endif

    !--- control volume points at the north pole
    do l = ADM_rgn_nmax, 1, -1
       if ( ADM_rgn_vnum(ADM_N,l) == ADM_VLINK_NMAX ) then
          do n = 1, ADM_VLINK_NMAX
             rgntab(n) = ADM_rgn_vtab(ADM_RID,ADM_N,l,n)
             prctab(n) = ADM_rgn2prc(rgntab(n))
          enddo
          exit
       endif
    enddo

    send_flag(:) = .false.

    do n = 1, ADM_VLINK_NMAX
       do l = 1, ADM_lall
          if ( ADM_prc_tab(l,ADM_prc_me) == rgntab(n) ) then
             vsend_pl(:,n) = GRD_xt(suf(ADM_gmin,ADM_gmax),ADM_KNONE,l,ADM_TJ,:) ! [mod] H.Yashiro 20120525

             call MPI_ISEND( vsend_pl(:,n),  &
                             3,              &
                             datatype,       &
                             ADM_prc_npl-1,  &
                             rgntab(n),      &
                             ADM_COMM_WORLD, &
                             sreq(n),        &
                             ierr            )

             send_flag(n) = .true.
          endif
       enddo
    enddo

    if ( ADM_prc_me == ADM_prc_npl ) then
       do n = 1, ADM_VLINK_NMAX
          call MPI_IRECV( vrecv_pl(:,n),  &
                          3,              &
                          datatype,       &
                          prctab(n)-1,    &
                          rgntab(n),      &
                          ADM_COMM_WORLD, &
                          rreq(n),        &
                          ierr            )
       enddo
    endif

    do n = 1, ADM_VLINK_NMAX
       if ( send_flag(n) ) then
          call MPI_WAIT(sreq(n),istat,ierr)
       endif
    enddo

    if ( ADM_prc_me == ADM_prc_npl ) then
       do n = 1, ADM_VLINK_NMAX
          call MPI_WAIT(rreq(n),istat,ierr)
          GRD_xt_pl(n+1,ADM_KNONE,ADM_NPL,:) = vrecv_pl(:,n) ! [mod] H.Yashiro 20120525
       enddo
    endif

    !--- control volume points at the sourth pole
    do l = 1, ADM_rgn_nmax
       if ( ADM_rgn_vnum(ADM_S,l) == ADM_VLINK_NMAX ) then
          do n = 1, ADM_VLINK_NMAX
             rgntab(n) = ADM_rgn_vtab(ADM_RID,ADM_S,l,n)
             prctab(n) = ADM_rgn2prc(rgntab(n))
          enddo
          exit
       endif
    enddo

    call MPI_Barrier(ADM_COMM_world,ierr)

    send_flag(:) = .false.

    do n = 1, ADM_VLINK_NMAX
       do l =1, ADM_lall
          if (ADM_prc_tab(l,ADM_prc_me) == rgntab(n) ) then
             vsend_pl(:,n) = GRD_xt(suf(ADM_gmax,ADM_gmin),ADM_KNONE,l,ADM_TI,:) ! [mod] H.Yashiro 20120525

             call MPI_ISEND( vsend_pl(:,n),  &
                             3,              &
                             datatype,       &
                             ADM_prc_spl-1,  &
                             rgntab(n),      &
                             ADM_COMM_WORLD, &
                             sreq(n),        &
                             ierr            )

             send_flag(n) = .true.
          endif
       enddo
    enddo

    if ( ADM_prc_me == ADM_prc_spl ) then
       do n = 1, ADM_VLINK_NMAX
          call MPI_IRECV( vrecv_pl(:,n),  &
                          3,              &
                          datatype,       &
                          prctab(n)-1,    &
                          rgntab(n),      &
                          ADM_COMM_WORLD, &
                          rreq(n),        &
                          ierr            )
       enddo
    endif

    do n = 1, ADM_VLINK_NMAX
       if ( send_flag(n) ) then
          call MPI_WAIT(sreq(n),istat,ierr)
       endif
    enddo

    if ( ADM_prc_me == ADM_prc_spl ) then
       do n = 1, ADM_VLINK_NMAX
          call MPI_WAIT(rreq(n),istat,ierr)
          GRD_xt_pl(n+1,ADM_KNONE,ADM_SPL,:) = vrecv_pl(:,n) ! [mod] H.Yashiro 20120525
       enddo
    endif

    !--- grid point communication
    call COMM_var_DP( GRD_x, GRD_x_pl, ADM_KNONE, 3 )

    if (      ADM_prc_me == ADM_prc_npl &
         .OR. ADM_prc_me == ADM_prc_spl ) then
       GRD_xt_pl(ADM_GSLF_PL,:,:,:) = GRD_x_pl(ADM_GSLF_PL,:,:,:)
    endif

    return
  end subroutine GRD_gen_plgrid

  !-----------------------------------------------------------------------------
  !> scaling grid position on the plane/sphere
  subroutine GRD_scaling( fact )
    use mod_adm, only: &
       ADM_have_pl
    implicit none

    real(DP), intent(in) :: fact ! scaling factor
    !---------------------------------------------------------------------------

    GRD_x (:,:,:,:)   = GRD_x (:,:,:,:)   * fact
    GRD_xt(:,:,:,:,:) = GRD_xt(:,:,:,:,:) * fact

    if ( ADM_have_pl ) then
       GRD_x_pl (:,:,:,:)   = GRD_x_pl (:,:,:,:) * fact
       GRD_xt_pl(:,:,:,:)   = GRD_xt_pl(:,:,:,:) * fact
    endif

    if ( GRD_grid_type == 'ON_PLANE' ) then
       ! do nothing
    else
       ! setting the sphere radius
       GRD_rscale = fact
    endif

    return
  end subroutine GRD_scaling

  !-----------------------------------------------------------------------------
  !> calculate location of the mid-point of cell arc
  subroutine GRD_makearc
    use mod_adm, only: &
       ADM_have_pl,    &
       ADM_gall_1d,    &
       ADM_gmin,       &
       ADM_gmax,       &
       ADM_gslf_pl,    &
       ADM_gmin_pl,    &
       ADM_gmax_pl
    implicit none

    integer :: ij
    integer :: im1j, ijm1

    integer :: nstart,nend
    integer :: n, l, v, K0
    !---------------------------------------------------------------------------

    K0 = ADM_KNONE

    do l = 1, ADM_lall
       nstart = suf(ADM_gmin-1,ADM_gmin  )
       nend   = suf(ADM_gmax  ,ADM_gmax  )

       do n = nstart, nend
          ij     = n
          ijm1   = n     - ADM_gall_1d

          GRD_xr(n,K0,l,ADM_AI ,GRD_XDIR) = 0.5_DP * ( GRD_xt(ijm1,K0,l,ADM_TJ,GRD_XDIR) + GRD_xt(ij,K0,l,ADM_TI,GRD_XDIR) )
          GRD_xr(n,K0,l,ADM_AI ,GRD_YDIR) = 0.5_DP * ( GRD_xt(ijm1,K0,l,ADM_TJ,GRD_YDIR) + GRD_xt(ij,K0,l,ADM_TI,GRD_YDIR) )
          GRD_xr(n,K0,l,ADM_AI ,GRD_ZDIR) = 0.5_DP * ( GRD_xt(ijm1,K0,l,ADM_TJ,GRD_ZDIR) + GRD_xt(ij,K0,l,ADM_TI,GRD_ZDIR) )
       enddo

       nstart = suf(ADM_gmin-1,ADM_gmin-1)
       nend   = suf(ADM_gmax  ,ADM_gmax  )

       do n = nstart, nend
          ij     = n

          GRD_xr(n,K0,l,ADM_AIJ,GRD_XDIR) = 0.5_DP * ( GRD_xt(ij,K0,l,ADM_TI,GRD_XDIR) + GRD_xt(ij,K0,l,ADM_TJ,GRD_XDIR) )
          GRD_xr(n,K0,l,ADM_AIJ,GRD_YDIR) = 0.5_DP * ( GRD_xt(ij,K0,l,ADM_TI,GRD_YDIR) + GRD_xt(ij,K0,l,ADM_TJ,GRD_YDIR) )
          GRD_xr(n,K0,l,ADM_AIJ,GRD_ZDIR) = 0.5_DP * ( GRD_xt(ij,K0,l,ADM_TI,GRD_ZDIR) + GRD_xt(ij,K0,l,ADM_TJ,GRD_ZDIR) )
       enddo

       nstart = suf(ADM_gmin  ,ADM_gmin-1)
       nend   = suf(ADM_gmax  ,ADM_gmax  )

       do n = nstart, nend
          ij     = n
          im1j   = n - 1

          GRD_xr(n,K0,l,ADM_AJ ,GRD_XDIR) = 0.5_DP * ( GRD_xt(ij,K0,l,ADM_TJ,GRD_XDIR) + GRD_xt(im1j,K0,l,ADM_TI,GRD_XDIR) )
          GRD_xr(n,K0,l,ADM_AJ ,GRD_YDIR) = 0.5_DP * ( GRD_xt(ij,K0,l,ADM_TJ,GRD_YDIR) + GRD_xt(im1j,K0,l,ADM_TI,GRD_YDIR) )
          GRD_xr(n,K0,l,ADM_AJ ,GRD_ZDIR) = 0.5_DP * ( GRD_xt(ij,K0,l,ADM_TJ,GRD_ZDIR) + GRD_xt(im1j,K0,l,ADM_TI,GRD_ZDIR) )
       enddo
    enddo

    if ( ADM_have_pl ) then
       n = ADM_gslf_pl

       do l = 1, ADM_lall_pl
          do v = ADM_gmin_pl, ADM_gmax_pl
             ij   = v
             ijm1 = v - 1
             if( ijm1 == ADM_gmin_pl - 1 ) ijm1 = ADM_gmax_pl

             GRD_xr_pl(v,K0,l,GRD_XDIR) = 0.5_DP * (GRD_xt_pl(ijm1,K0,l,GRD_XDIR)+GRD_xt_pl(ij,K0,l,GRD_XDIR))
             GRD_xr_pl(v,K0,l,GRD_YDIR) = 0.5_DP * (GRD_xt_pl(ijm1,K0,l,GRD_YDIR)+GRD_xt_pl(ij,K0,l,GRD_YDIR))
             GRD_xr_pl(v,K0,l,GRD_ZDIR) = 0.5_DP * (GRD_xt_pl(ijm1,K0,l,GRD_ZDIR)+GRD_xt_pl(ij,K0,l,GRD_ZDIR))
          enddo
       enddo
    endif

    return
  end subroutine GRD_makearc

  !-----------------------------------------------------------------------------
  integer function suf(i,j)
    use mod_adm, only: &
       ADM_gall_1d
    implicit none

    integer :: i, j
    !---------------------------------------------------------------------------

    suf = ADM_gall_1d * (j-1) + i

  end function suf

end module mod_grd
!-------------------------------------------------------------------------------
