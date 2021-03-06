!-------------------------------------------------------------------------------
!>
!! History history variables
!!
!! @par Description
!!         This module prepares diagnostic/prognostic variavles for histroy output
!!
!! @author W.Yanase, S.Iga, H.Tomita, Y.Niwa
!!
!! @par History
!! @li      2007-06-27   Y.Niwa  : Imported from mod_history_vars_cfmip
!! @li      2007-07-31   K.Suzuki: add SPRINTARS variables
!! @li      2007-08-06   Y.Niwa  : bug fix  'th' => 'ml_th' 'rh' => 'ml_rh'
!! @li      2007-08-06   K.Suzuki: move SPRINTARS variables from mod_postphystep
!! @li      2007-08-20   W.Yanase: debug in "call getr1_in_mat"
!! @li      2007-11-22   T.Mitsui: Effective Radius is calculated in rd_driver => mp_driver
!!                                 and some variables are moved from aerovar
!! @li      2007-11-30   T.Mitsui: del double use(trivial)
!! @li      2007-12-05   T.Mitsui: add radiative flux categolized as ISCCP-D series
!! @li      2008-02-19   T.Mitsui: Add output for slice-cloud normalized by cot
!!                                 and trivial fix for output option
!! @li      2008-03-06   H.Tomita: add mp_wsm3_wcdiag.
!! @li      2008-05-24   T.Mitsui: add nc, nr, ni, ns, ng for 2moment option
!! @li      2008-06-13   T.Mitsui: change adiabat_diag => adiabat_diag2
!!                                 and add arguments (positive only cape, and all cin)
!! @li      2008-07-30   W.Yanase: add sl_u10m, sl_v10m, sl_tauu, sl_tauv
!! @li      2009-01-23   H.Tomita: add ml_omg, ml_hgt
!! @li      2009-04-14   H.Tomita: bugfix : zero clear of lwpqc,lwpqr.
!! @li      2009-04-14   T.Mitsui: sl_nc,r,i,s,g and sl_tauc,r,i,s,g
!!                                 sl_qi, sl_qg
!! @li      2009-07-10   H.Tomita: 1. The energy conservation terms are added.
!!                                 2. Some tag names were changed to avoid the confusion.
!!                                   'sl_swi' -> 'sl_swd_sfc'
!!                                   'sl_sswr' -> 'sl_swu_sfc'
!!                                   'sl_slwd' -> 'sl_lwd_sfc'
!!                                   'sl_slwu' -> 'sl_lwu_sfc'
!!                                   'sl_slh' ->  'sl_lh_sfc'
!!                                   'sl_ssh' ->  'sl_sh_sfc'
!!                                   'sl_sw_toai' ->  'sl_swd_toa'
!!                                   'sl_sw_toar' ->  'sl_swu_toa'
!!                                   'sl_lw_toa' ->  'sl_lwu_toa'
!! @li      2009-07-13   S.Iga   : Bug fix 'sl_lw_toa' ->  'sl_lwu_toa'
!! @li      2010-06-19   A.T.Noda: Allow to use a convection parameterization
!!                                 with an advanced microphysics schemes, such as G98, NSW?,
!! @li      2010-08-20   C.Kodama: land model output is filled with undef values over the ocean.
!! @li      2012-11-05 (H.Yashiro)  NICAM milestone project (Phase I:cleanup of shared module)
!!
!<
module mod_history_vars
  !-----------------------------------------------------------------------------
  !
  !++ Used modules
  !
  use mod_precision
  use mod_debug
  use mod_adm, only: &
     ADM_LOG_FID,  &
     ADM_MAXFNAME, &
     ADM_NSYS
  !-----------------------------------------------------------------------------
  implicit none
  private
  real(RP), save, allocatable :: u_old (:, :, :)
  real(RP), save, allocatable :: v_old (:, :, :)
  real(RP), save, allocatable :: wc_old(:, :, :)
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: history_vars_setup
  public :: history_vars

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private procedure
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  logical, private :: out_uv_cos   = .false.
  logical, private :: out_omg      = .false.
  logical, private :: out_th       = .false.
  logical, private :: out_th_prime = .false.
  logical, private :: out_850hPa   = .false.
  logical, private :: out_500hPa   = .false.

  logical, private :: out_rh       = .false.
  logical, private :: out_pw       = .false.
  logical, private :: out_lwp      = .false.
  logical, private :: out_iwp      = .false.
  logical, private :: out_duvw      = .false.

  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  subroutine history_vars_setup
    use mod_history, only: &
       HIST_req_nmax, &
       item_save
    use mod_adm, only: &
       ADM_gall, &
       ADM_kall, &
       ADM_lall, &
       ADM_KNONE
    use mod_runconf, only: &
       TRC_VMAX,  &
       AF_TYPE
    use mod_history, only: &
       history_in
    implicit none

    real(RP) :: tmp3d(ADM_gall,ADM_kall)
    real(RP) :: tmp2d(ADM_gall,ADM_KNONE)

    character(len=16) :: varname

    integer :: n, l, nq
    !---------------------------------------------------------------------------

    do n = 1, HIST_req_nmax
       if(      item_save(n) == 'ml_ucos'     &
           .OR. item_save(n) == 'ml_vcos'     ) out_uv_cos   = .true.
       if(      item_save(n) == 'ml_omg'      ) out_omg      = .true.
       if(      item_save(n) == 'ml_th'       ) out_th       = .true.
       if(      item_save(n) == 'ml_th_prime' ) out_th_prime = .true.
       if(      item_save(n) == 'sl_u850'     &
           .OR. item_save(n) == 'sl_v850'     &
           .OR. item_save(n) == 'sl_w850'     &
           .OR. item_save(n) == 'sl_t850'     ) out_850hPa   = .true.
       if(      item_save(n) == 'sl_u500'     &
           .OR. item_save(n) == 'sl_v500'     &
           .OR. item_save(n) == 'sl_w500'     &
           .OR. item_save(n) == 'sl_t500'     ) out_500hPa   = .true.

       if(      item_save(n) == 'ml_rh'       ) out_rh       = .true.
       if(      item_save(n) == 'sl_pw'       ) out_pw       = .true.
       if(      item_save(n) == 'sl_lwp'      ) out_lwp      = .true.
       if(      item_save(n) == 'sl_iwp'      ) out_iwp      = .true.

       if(      item_save(n) == 'ml_du'      &
           .OR. item_save(n) == 'ml_dv'      &
           .OR. item_save(n) == 'ml_dw'      ) then
          out_duvw      = .true.
       end if

    enddo
    if ( out_duvw ) then
       allocate( u_old (ADM_gall,ADM_kall,ADM_lall) )
       allocate( v_old (ADM_gall,ADM_kall,ADM_lall) )
       allocate( wc_old(ADM_gall,ADM_kall,ADM_lall) )
    endif

    tmp2d(:,:) = 0.0_RP
    tmp3d(:,:) = 0.0_RP

    select case(AF_TYPE)
    case('HELD-SUAREZ')
       do l = 1, ADM_lall
          call history_in( 'ml_af_fvx', tmp3d(:,:) )
          call history_in( 'ml_af_fvy', tmp3d(:,:) )
          call history_in( 'ml_af_fvz', tmp3d(:,:) )
          call history_in( 'ml_af_fe',  tmp3d(:,:) )
       enddo
    case('DCMIP2016')
       do l = 1, ADM_lall

          call history_in( 'ml_af_fvx', tmp3d(:,:) )
          call history_in( 'ml_af_fvy', tmp3d(:,:) )
          call history_in( 'ml_af_fvz', tmp3d(:,:) )
          call history_in( 'ml_af_fe',  tmp3d(:,:) )

          do nq = 1, TRC_VMAX
             write(varname,'(A,I2.2)') 'ml_af_fq', nq

             call history_in( varname, tmp3d(:,:) )
          enddo

          call history_in( 'sl_af_prcp', tmp2d(:,:) )
       enddo
    end select

    return
  end subroutine history_vars_setup

  !----------------------------------------------------------------------
  subroutine history_vars
    use mod_adm, only: &
       ADM_have_pl, &
       ADM_gall,    &
       ADM_gall_pl, &
       ADM_kall,    &
       ADM_lall,    &
       ADM_lall_pl, &
       ADM_KNONE,   &
       ADM_kmin,    &
       ADM_kmax
    use mod_cnst, only: &
       CNST_EGRAV
    use mod_grd, only: &
       GRD_dgz,  &
       GRD_ZSFC, &
       GRD_Z,    &
       GRD_zs,   &
       GRD_vz
    use mod_vmtr, only: &
       VMTR_PHI,    &
       VMTR_GSGAM2
    use mod_gtl, only: &
       GTL_generate_uv,          &
       GTL_global_sum_eachlayer, &
       GTL_clip_region_1layer,   &  ! [add] 2010.08.20 C.Kodama
       GTL_max, &
       GTL_min
    use mod_prgvar, only: &
       prgvar_get_withdiag
    use mod_runconf, only: &
       TRC_VMAX,  &
       TRC_name,  &
       NQW_STR,   &
       NQW_END,   &
       I_QV,      &
       I_QC,      &
       I_QR,      &
       I_QI,      &
       I_QS,      &
       I_QG,      &
       AF_TYPE,   &
       NCHEM_STR, &
       NCHEM_END
    use mod_thrmdyn, only: &
       THRMDYN_th
    use mod_bndcnd, only: &
       bndcnd_thermo
    use mod_history, only: &
       history_in
    implicit none

    real(RP) :: rhog     (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: rhog_pl  (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: rhogvx   (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: rhogvx_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: rhogvy   (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: rhogvy_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: rhogvz   (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: rhogvz_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: rhogw    (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: rhogw_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: rhoge    (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: rhoge_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: rhogq    (ADM_gall   ,ADM_kall,ADM_lall   ,TRC_vmax)
    real(RP) :: rhogq_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl,TRC_vmax)
    real(RP) :: rho      (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: rho_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: pre      (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: pre_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: tem      (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: tem_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: vx       (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: vx_pl    (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: vy       (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: vy_pl    (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: vz       (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: vz_pl    (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: w        (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: w_pl     (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: q        (ADM_gall,   ADM_kall,ADM_lall,   TRC_vmax)
    real(RP) :: q_pl     (ADM_gall_pl,ADM_kall,ADM_lall_pl,TRC_vmax)

    real(RP) :: u        (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: u_pl     (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: v        (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: v_pl     (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: ucos     (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: vcos     (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: wc       (ADM_gall   ,ADM_kall,ADM_lall   )

    real(RP) :: omg      (ADM_gall   ,ADM_kall,ADM_lall   )

    real(RP) :: u_850    (ADM_gall   ,ADM_KNONE,ADM_lall   ) ! [add] 20130705 R.Yoshida
    real(RP) :: v_850    (ADM_gall   ,ADM_KNONE,ADM_lall   )
    real(RP) :: w_850    (ADM_gall   ,ADM_KNONE,ADM_lall   )
    real(RP) :: t_850    (ADM_gall   ,ADM_KNONE,ADM_lall   )
    real(RP) :: u_500    (ADM_gall   ,ADM_KNONE,ADM_lall   ) ! [add] 20130705 R.Yoshida
    real(RP) :: v_500    (ADM_gall   ,ADM_KNONE,ADM_lall   )
    real(RP) :: w_500    (ADM_gall   ,ADM_KNONE,ADM_lall   )
    real(RP) :: t_500    (ADM_gall   ,ADM_KNONE,ADM_lall   )
    real(RP) :: rho_sfc  (ADM_gall   ,ADM_KNONE,ADM_lall   )
    real(RP) :: pre_sfc  (ADM_gall   ,ADM_KNONE,ADM_lall   )

    real(RP) :: th_prime (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: one      (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: one_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: area_prof(ADM_kall)
    real(RP) :: th       (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: th_pl    (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: th_prof  (ADM_kall)

!    real(RP) :: rh      (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: q_clw    (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: q_cli    (ADM_gall   ,ADM_kall,ADM_lall   )
    real(RP) :: qtot     (ADM_gall   ,ADM_kall,ADM_lall   )

    real(RP) :: tmp2d    (ADM_gall   ,ADM_KNONE,ADM_lall   )
    real(RP) :: rhodz    (ADM_gall   ,ADM_KNONE,ADM_lall   )

    integer :: k, l, nq, K0
    !---------------------------------------------------------------------------

    K0 = ADM_KNONE

    !--- get variables
    call prgvar_get_withdiag( rhog,   rhog_pl,   & ! [OUT]
                              rhogvx, rhogvx_pl, & ! [OUT]
                              rhogvy, rhogvy_pl, & ! [OUT]
                              rhogvz, rhogvz_pl, & ! [OUT]
                              rhogw,  rhogw_pl,  & ! [OUT]
                              rhoge,  rhoge_pl,  & ! [OUT]
                              rhogq,  rhogq_pl,  & ! [OUT]
                              rho,    rho_pl,    & ! [OUT]
                              pre,    pre_pl,    & ! [OUT]
                              tem,    tem_pl,    & ! [OUT]
                              vx,     vx_pl,     & ! [OUT]
                              vy,     vy_pl,     & ! [OUT]
                              vz,     vz_pl,     & ! [OUT]
                              w,      w_pl,      & ! [OUT]
                              q,      q_pl       ) ! [OUT]

    ! boundary condition
    do l = 1, ADM_lall
       call bndcnd_thermo( ADM_gall,        & ! [IN]
                           tem     (:,:,l), & ! [INOUT]
                           rho     (:,:,l), & ! [INOUT]
                           pre     (:,:,l), & ! [INOUT]
                           VMTR_PHI(:,:,l)  ) ! [IN]
    enddo

    ! zonal and meridonal wind
    call GTL_generate_uv( u,  u_pl,  & ! [OUT]
                          v,  v_pl,  & ! [OUT]
                          vx, vx_pl, & ! [IN]
                          vy, vy_pl, & ! [IN]
                          vz, vz_pl, & ! [IN]
                          icos = 0   ) ! [IN]

    ! vertical wind at cell center
    do l = 1, ADM_lall
       do k = ADM_kmin, ADM_kmax
          wc(:,k,l) = 0.5_RP * ( w(:,k,l) + w(:,k+1,l) )
       enddo
       wc(:,ADM_kmin-1,l) = 0.0_RP
       wc(:,ADM_kmax+1,l) = 0.0_RP
    enddo



    do l = 1, ADM_lall
       call history_in( 'ml_rho',  rho(:,:,l) )
       call history_in( 'ml_tem',  tem(:,:,l) )
       call history_in( 'ml_pres', pre(:,:,l) )

       call history_in( 'ml_u',    u  (:,:,l) )
       call history_in( 'ml_v',    v  (:,:,l) )
       call history_in( 'ml_w',    wc (:,:,l) )

       call history_in( 'ml_hgt',  real(GRD_vz(:,:,l,GRD_Z),kind=RP) ) ! geopotential height: Hydrostatic assumption
    enddo

    if (out_duvw) then
       do l = 1, ADM_lall
          call history_in( 'ml_du',    u  (:,:,l) -u_old (:,:,l) )
          call history_in( 'ml_dv',    v  (:,:,l) -v_old (:,:,l) )
          call history_in( 'ml_dw',    wc (:,:,l) -wc_old(:,:,l) )
       end do

       u_old(:,:,:) = u(:,:,:)
       v_old(:,:,:) = v(:,:,:)
       wc_old(:,:,:) = wc(:,:,:)
    end if

    ! zonal and meridonal wind with cos(phi)
    if (out_uv_cos) then
       call GTL_generate_uv( ucos, u_pl,  & ! [OUT]
                             vcos, v_pl,  & ! [OUT]
                             vx,   vx_pl, & ! [IN]
                             vy,   vy_pl, & ! [IN]
                             vz,   vz_pl, & ! [IN]
                             icos = 1     ) ! [IN]

       do l = 1, ADM_lall
          call history_in( 'ml_ucos', ucos(:,:,l) )
          call history_in( 'ml_vcos', vcos(:,:,l) )
       enddo
    endif

    ! omega
    if (out_omg) then
       do l = 1, ADM_lall
          omg(:,:,l) = -CNST_EGRAV * rho(:,:,l) * wc(:,:,l)

          call history_in( 'ml_omg', omg(:,:,l) )
       enddo
    endif

    ! potential temperature
    if ( out_th ) then
       call THRMDYN_th( ADM_gall,   & ! [IN]
                        ADM_kall,   & ! [IN]
                        ADM_lall,   & ! [IN]
                        tem(:,:,:), & ! [IN]
                        pre(:,:,:), & ! [IN]
                        th (:,:,:)  ) ! [OUT]

       do l = 1, ADM_lall
          call history_in( 'ml_th', th(:,:,l) )
       enddo
    endif

    if ( out_th_prime ) then
       one   (:,:,:) = 1.0_RP
       one_pl(:,:,:) = 1.0_RP

       call GTL_global_sum_eachlayer( one, one_pl, area_prof )

       call THRMDYN_th( ADM_gall,   & ! [IN]
                        ADM_kall,   & ! [IN]
                        ADM_lall,   & ! [IN]
                        tem(:,:,:), & ! [IN]
                        pre(:,:,:), & ! [IN]
                        th (:,:,:)  ) ! [OUT]

       if ( ADM_have_pl ) then
          call THRMDYN_th( ADM_gall_pl,   & ! [IN]
                           ADM_kall,      & ! [IN]
                           ADM_lall_pl,   & ! [IN]
                           tem_pl(:,:,:), & ! [IN]
                           pre_pl(:,:,:), & ! [IN]
                           th_pl (:,:,:)  ) ! [OUT]
       endif

       call GTL_global_sum_eachlayer( th, th_pl, th_prof )

       do l = 1, ADM_lall
          do k = 1, ADM_kall
             th_prime(:,k,l) = th(:,k,l) - th_prof(k) / area_prof(k)
          enddo

          call history_in( 'ml_th_prime', th_prime(:,:,l) )
       enddo
    endif

    if (out_850hPa) then   ! [add] 20130705 R.Yoshida
       do l = 1, ADM_lall
          call sv_plev_uvwt( ADM_gall,        & ! [IN]
                             pre    (:,:,l),  & ! [IN]
                             u      (:,:,l),  & ! [IN]
                             v      (:,:,l),  & ! [IN]
                             w      (:,:,l),  & ! [IN]
                             tem    (:,:,l),  & ! [IN]
                             85000.0_RP,      & ! [IN]
                             u_850  (:,K0,l), & ! [OUT]
                             v_850  (:,K0,l), & ! [OUT]
                             w_850  (:,K0,l), & ! [OUT]
                             t_850  (:,K0,l)  ) ! [OUT]

          call history_in( 'sl_u850', u_850(:,:,l) )
          call history_in( 'sl_v850', v_850(:,:,l) )
          call history_in( 'sl_w850', w_850(:,:,l) )
          call history_in( 'sl_t850', t_850(:,:,l) )
       enddo
    endif

    if (out_500hPa) then
       do l = 1, ADM_lall
          call sv_plev_uvwt( ADM_gall,        & ! [IN]
                             pre    (:,:,l),  & ! [IN]
                             u      (:,:,l),  & ! [IN]
                             v      (:,:,l),  & ! [IN]
                             w      (:,:,l),  & ! [IN]
                             tem    (:,:,l),  & ! [IN]
                             50000.0_RP,      & ! [IN]
                             u_500  (:,K0,l), & ! [OUT]
                             v_500  (:,K0,l), & ! [OUT]
                             w_500  (:,K0,l), & ! [OUT]
                             t_500  (:,K0,l)  ) ! [OUT]

          call history_in( 'sl_u500', u_500(:,:,l) )
          call history_in( 'sl_v500', v_500(:,:,l) )
          call history_in( 'sl_w500', w_500(:,:,l) )
          call history_in( 'sl_t500', t_500(:,:,l) )
       enddo
    endif

    do l = 1, ADM_lall
       call sv_pre_sfc( ADM_gall,                 & ! [IN]
                        rho    (:,:,l),           & ! [IN]
                        pre    (:,:,l),           & ! [IN]
                        real(GRD_vz (:,:,l,GRD_Z),kind=RP),     & ! [IN]
                        real(GRD_zs (:,K0,l,GRD_ZSFC),kind=RP), & ! [IN]
                        rho_sfc(:,K0,l),          & ! [OUT]
                        pre_sfc(:,K0,l)           ) ! [OUT]

       call history_in( 'sl_ps', pre_sfc(:,:,l) )
    enddo



    !### tracers ###

    ! tracers
    do nq = 1, TRC_vmax
    do l  = 1, ADM_lall
       call history_in( 'ml_'//TRC_name(nq), q(:,:,l,nq) )
    enddo
    enddo

    ! relative humidity
!    if (out_rh) then
!       call moist_relative_humidity( rh(:,:,l),    & ! [OUT]
!                                     rho(:,:,l),   & ! [IN]
!                                     tem(:,:,l),   & ! [IN]
!                                     q(:,:,l,I_QV) ) ! [IN]
!
!       call history_in( 'ml_rh', rh(:,:,l) )
!    endif

    ! hydrometeors
    do l  = 1, ADM_lall
       q_clw(:,:,l) = 0.0_RP
       q_cli(:,:,l) = 0.0_RP
       do nq = NQW_STR, NQW_END
          if ( nq == I_QC ) then
             q_clw(:,:,l) = q_clw(:,:,l) + q(:,:,l,nq)
          elseif( nq == I_QR ) then
             q_clw(:,:,l) = q_clw(:,:,l) + q(:,:,l,nq)
          elseif( nq == I_QI ) then
             q_cli(:,:,l) = q_cli(:,:,l) + q(:,:,l,nq)
          elseif( nq == I_QS ) then
             q_cli(:,:,l) = q_cli(:,:,l) + q(:,:,l,nq)
          elseif( nq == I_QG ) then
             q_cli(:,:,l) = q_cli(:,:,l) + q(:,:,l,nq)
          endif
       enddo
    enddo

    do l = 1, ADM_lall
       qtot(:,:,l) = q_clw(:,:,l) + q_cli(:,:,l)

       call history_in( 'ml_qtot', qtot(:,:,l) )
    enddo

    if (out_pw) then
       do l = 1, ADM_lall
          do k = ADM_kmin, ADM_kmax
             tmp2d(:,K0,l) = tmp2d(:,K0,l) + rho(:,k,l) * q(:,k,l,I_QV) * VMTR_GSGAM2(:,k,l) * GRD_dgz(k)
          enddo
          call history_in( 'sl_pw', tmp2d(:,:,l) )
       enddo
    endif

    if (out_lwp) then
       do l = 1, ADM_lall
          tmp2d(:,K0,l) = 0.0_RP
          do k = ADM_kmin, ADM_kmax
             tmp2d(:,K0,l) = tmp2d(:,K0,l) + rho(:,k,l) * q_clw(:,k,l) * VMTR_GSGAM2(:,k,l) * GRD_dgz(k)
          enddo
          call history_in( 'sl_lwp', tmp2d(:,:,l) )
       enddo
    endif

    if (out_iwp) then
       do l  = 1, ADM_lall
          tmp2d(:,K0,l) = 0.0_RP
          do k = ADM_kmin, ADM_kmax
             tmp2d(:,K0,l) = tmp2d(:,K0,l) + rho(:,k,l) * q_cli(:,k,l) * VMTR_GSGAM2(:,k,l) * GRD_dgz(k)
          enddo
          call history_in( 'sl_iwp', tmp2d(:,:,l) )
       enddo
    endif

    if ( AF_TYPE == 'DCMIP2016' ) then
    if ( NCHEM_STR /= -1 .and. NCHEM_END /= -1 ) then ! substitution of [USE_ToyChemistry/mod_af_dcmip2016]
       do l  = 1, ADM_lall
          rhodz(:,k0,l) = 0.0_RP
          do k = ADM_kmin, ADM_kmax
             rhodz(:,k0,l) = rhodz(:,k0,l) + ( rho(:,k,l) * VMTR_GSGAM2(:,k,l) * GRD_dgz(k) )
          enddo

          tmp2d(:,k0,l) = 0.0_RP
          do k = ADM_kmin, ADM_kmax
             tmp2d(:,k0,l) = tmp2d(:,k0,l) &
                           + rho(:,k,l) * q(:,k,l,NCHEM_STR) * VMTR_GSGAM2(:,k,l) * GRD_dgz(k)
          enddo
          tmp2d(:,k0,l) = tmp2d(:,k0,l) / rhodz(:,k0,l)
          call history_in( 'sl_cl', tmp2d(:,:,l) )

          tmp2d(:,k0,l) = 0.0_RP
          do k = ADM_kmin, ADM_kmax
             tmp2d(:,k0,l) = tmp2d(:,k0,l) &
                           + rho(:,k,l) * q(:,k,l,NCHEM_END) * VMTR_GSGAM2(:,k,l) * GRD_dgz(k)
          enddo
          tmp2d(:,k0,l) = tmp2d(:,k0,l) / rhodz(:,k0,l)
          call history_in( 'sl_cl2', tmp2d(:,:,l) )

          tmp2d(:,k0,l) = 0.0_RP
          do k = ADM_kmin, ADM_kmax
             tmp2d(:,k0,l) = tmp2d(:,k0,l) &
                           + rho(:,k,l) * ( q(:,k,l,NCHEM_STR) + 2.0_RP * q(:,k,l,NCHEM_END) ) &
                           * VMTR_GSGAM2(:,k,l) * GRD_dgz(k)
          enddo
          tmp2d(:,k0,l) = tmp2d(:,k0,l) / rhodz(:,k0,l)
          call history_in( 'sl_cly', tmp2d(:,:,l) )
       enddo
    endif
    endif

    return
  end subroutine history_vars

  !-----------------------------------------------------------------------------
  subroutine sv_pre_sfc( &
       ijdim,   &
       rho,     &
       pre,     &
       z,       &
       z_srf,   &
       rho_srf, &
       pre_srf  )
    use mod_adm, only :  &
       kdim => ADM_kall,    &
       kmin => ADM_kmin
    use mod_cnst, only :  &
       CNST_EGRAV
    implicit none

    integer, intent(in)  :: ijdim
    real(RP), intent(in)  :: rho    (ijdim,kdim)
    real(RP), intent(in)  :: pre    (ijdim,kdim)
    real(RP), intent(in)  :: z      (ijdim,kdim)
    real(RP), intent(in)  :: z_srf  (ijdim)
    real(RP), intent(out) :: rho_srf(ijdim)
    real(RP), intent(out) :: pre_srf(ijdim)

    integer :: ij
    !---------------------------------------------------------------------------

    !--- surface density ( extrapolation )
    do ij = 1, ijdim
       rho_srf(ij) = rho(ij,kmin) &
                   - ( rho(ij,kmin+1)-rho(ij,kmin) ) * ( z(ij,kmin)-z_srf(ij) ) / ( z(ij,kmin+1)-z(ij,kmin) )
    enddo

    !--- surface pressure ( hydrostatic balance )
    do ij = 1, ijdim
       pre_srf(ij) = pre(ij,kmin) + rho(ij,kmin) * CNST_EGRAV * ( z(ij,kmin)-z_srf(ij) )
    enddo

    return
  end subroutine sv_pre_sfc

  !-----------------------------------------------------------------------------
  ! [add] 20130705 R.Yoshida
  subroutine sv_plev_uvwt( &
       ijdim, &
       pre,   &
       u_z,   &
       v_z,   &
       w_z,   &
       t_z,   &
       plev,  &
       u_p,   &
       v_p,   &
       w_p,   &
       t_p    )
    use mod_adm, only: &
       ADM_proc_stop,    &
       kdim => ADM_kall, &
       kmin => ADM_kmin
    implicit none

    integer, intent(in)  :: ijdim
    real(RP), intent(in)  :: pre(ijdim,kdim)
    real(RP), intent(in)  :: u_z(ijdim,kdim)
    real(RP), intent(in)  :: v_z(ijdim,kdim)
    real(RP), intent(in)  :: w_z(ijdim,kdim)
    real(RP), intent(in)  :: t_z(ijdim,kdim)
    real(RP), intent(in)  :: plev
    real(RP), intent(out) :: u_p(ijdim)
    real(RP), intent(out) :: v_p(ijdim)
    real(RP), intent(out) :: w_p(ijdim)
    real(RP), intent(out) :: t_p(ijdim)

    integer :: kl(ijdim)
    integer :: ku(ijdim)

    real(RP) :: wght_l, wght_u

    integer :: ij, k
    !---------------------------------------------------------------------------

    ! search z-level
    do ij = 1, ijdim
       do k = kmin, kdim
          if( pre(ij,k) < plev ) exit
       enddo
       if ( k >= kdim ) then
          write(*,          *) 'xxx internal error! [sv_plev_uvwt/mod_history_vars] STOP.'
          write(ADM_LOG_FID,*) 'xxx internal error! [sv_plev_uvwt/mod_history_vars] STOP.',kdim,k,plev,ij,pre(ij,:)
          call ADM_proc_stop
       endif

       ku(ij) = k
       kl(ij) = k - 1
    enddo

    ! interpolate
    do ij = 1, ijdim
       wght_l = ( log(plev)           - log(pre(ij,ku(ij))) ) &
              / ( log(pre(ij,kl(ij))) - log(pre(ij,ku(ij))) )

       wght_u = ( log(pre(ij,kl(ij))) - log(plev)           ) &
              / ( log(pre(ij,kl(ij))) - log(pre(ij,ku(ij))) )

       u_p(ij) = wght_l * u_z(ij,kl(ij)) + wght_u * u_z(ij,ku(ij))
       v_p(ij) = wght_l * v_z(ij,kl(ij)) + wght_u * v_z(ij,ku(ij))
       w_p(ij) = wght_l * w_z(ij,kl(ij)) + wght_u * w_z(ij,ku(ij))
       t_p(ij) = wght_l * t_z(ij,kl(ij)) + wght_u * t_z(ij,ku(ij))
    enddo

    return
  end subroutine sv_plev_uvwt

end module mod_history_vars
!-------------------------------------------------------------------------------
