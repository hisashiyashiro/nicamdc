!-------------------------------------------------------------------------------
!>
!! variable conversion module
!!
!! @par Description
!!         Conversion tools for prognostic variables
!!
!! @author H.Tomita
!!
!! @par History
!! @li      2004-02-17 (H.Tomita)   Imported from igdc-4.34
!! @li      2009-07-10 (H.Tomita)   Change the cnvvar_rhokin, cnvvar_kin for the energy conservation.
!! @li      2011-07-22 (T.Ohno)     add subroutines for plane hgrid systems
!!
!<
module mod_cnvvar
  !-----------------------------------------------------------------------------
  !
  !++ Used modules
  !
  use mod_debug
  use mod_adm, only: &
     ADM_LOG_FID
  use mod_runconf, only: &
     PRG_vmax0,  &
     I_RHOG,     &
     I_RHOGVX,   &
     I_RHOGVY,   &
     I_RHOGVZ,   &
     I_RHOGW,    &
     I_RHOGE,    &
     I_RHOGQstr, &
     I_RHOGQend, &
     DIAG_vmax0, &
     I_pre,      &
     I_tem,      &
     I_vx,       &
     I_vy,       &
     I_vz,       &
     I_w,        &
     I_qstr,     &
     I_qend
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: cnvvar_prg2diag
  public :: cnvvar_diag2prg
  public :: cnvvar_rhogkin

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private procedures
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  subroutine cnvvar_prg2diag(&
       prg,  prg_pl, &
       diag, diag_pl )
    use mod_adm, only: &
       ADM_prc_me,  &
       ADM_prc_pl,  &
       ADM_gall,    &
       ADM_gall_pl, &
       ADM_lall,    &
       ADM_lall_pl, &
       ADM_kall
    use mod_vmtr, only : &
       VMTR_RGSGAM2,    &
       VMTR_RGSGAM2_pl, &
       VMTR_C2Wfact,    &
       VMTR_C2Wfact_pl
    use mod_runconf, only: &
       PRG_vmax,  &
       DIAG_vmax, &
       TRC_vmax,  &
       NQW_STR,   &
       NQW_END
    use mod_thrmdyn, only: &
       THRMDYN_qd_ijkl,    &
       THRMDYN_tempre_ijkl
    implicit none

    real(8), intent(in)  :: prg    (ADM_gall,   ADM_kall,ADM_lall,   PRG_vmax )
    real(8), intent(in)  :: prg_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl,PRG_vmax )
    real(8), intent(out) :: diag   (ADM_gall,   ADM_kall,ADM_lall,   DIAG_vmax)
    real(8), intent(out) :: diag_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl,DIAG_vmax)

    real(8) :: qd       (ADM_gall,   ADM_kall,ADM_lall   )
    real(8) :: qd_pl    (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8) :: rho      (ADM_gall,   ADM_kall,ADM_lall   )
    real(8) :: rho_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8) :: ein      (ADM_gall,   ADM_kall,ADM_lall   )
    real(8) :: ein_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)

    real(8) :: rhog_h   (ADM_gall,   ADM_kall)
    real(8) :: rhog_h_pl(ADM_gall_pl,ADM_kall)

    integer :: n, k, l, iv
    !---------------------------------------------------------------------------

    do l = 1, ADM_lall
    do k = 1, ADM_kall
    do n = 1, ADM_gall
       rho (n,k,l)      = prg(n,k,l,I_RHOG  ) * VMTR_RGSGAM2(n,k,l)
       diag(n,k,l,I_vx) = prg(n,k,l,I_RHOGVX) / prg(n,k,l,I_RHOG)
       diag(n,k,l,I_vy) = prg(n,k,l,I_RHOGVY) / prg(n,k,l,I_RHOG)
       diag(n,k,l,I_vz) = prg(n,k,l,I_RHOGVZ) / prg(n,k,l,I_RHOG)
       ein (n,k,l)      = prg(n,k,l,I_RHOGE ) / prg(n,k,l,I_RHOG)
    enddo
    enddo
    enddo

    do iv = 1, TRC_vmax
    do l  = 1, ADM_lall
    do k  = 1, ADM_kall
    do n  = 1, ADM_gall
       diag(n,k,l,DIAG_vmax0+iv) = prg(n,k,l,PRG_vmax0+iv) / prg(n,k,l,I_RHOG)
    enddo
    enddo
    enddo
    enddo

    !--- calculation of dry mass concentration
    call THRMDYN_qd_ijkl( ADM_gall, ADM_kall, ADM_lall, & !--- [IN]
                          TRC_vmax, NQW_STR, NQW_END,   & !--- [IN]
                          qd  (:,:,:),                  & !--- [OUT]
                          diag(:,:,:,I_qstr:I_qend)     ) !--- [IN]

    !--- calculation of tem, pre
    call THRMDYN_tempre_ijkl( ADM_gall, ADM_kall, ADM_lall, & !--- [IN]
                              TRC_vmax, NQW_STR, NQW_END,   & !--- [IN]
                              diag(:,:,:,I_tem),            & !--- [OUT]
                              diag(:,:,:,I_pre),            & !--- [OUT]
                              ein(:,:,:),                   & !--- [IN]
                              rho(:,:,:),                   & !--- [IN]
                              qd  (:,:,:),                  & !--- [IN]
                              diag(:,:,:,I_qstr:I_qend)     ) !--- [IN]

    do l = 1, ADM_lall
       !------ interpolation of rhog_h
       do k = 2, ADM_kall
       do n = 1, ADM_gall
          rhog_h(n,k) = ( VMTR_C2Wfact(n,k,1,l) * prg(n,k  ,l,I_RHOG) &
                        + VMTR_C2Wfact(n,k,2,l) * prg(n,k-1,l,I_RHOG) )
       enddo
       enddo
       do n = 1, ADM_gall
          rhog_h(n,1) = rhog_h(n,2)
       enddo

       do k = 1, ADM_kall
       do n = 1, ADM_gall
          diag(n,k,l,I_w) = prg(n,k,l,I_RHOGW) / rhog_h(n,k)
       enddo
       enddo
    enddo

    if ( ADM_prc_me == ADM_prc_pl ) then

       do l = 1, ADM_lall_pl
       do k = 1, ADM_kall
       do n = 1, ADM_gall_pl
          rho_pl (n,k,l)      = prg_pl(n,k,l,I_RHOG  ) * VMTR_RGSGAM2_pl(n,k,l)
          diag_pl(n,k,l,I_vx) = prg_pl(n,k,l,I_RHOGVX) / prg_pl(n,k,l,I_RHOG)
          diag_pl(n,k,l,I_vy) = prg_pl(n,k,l,I_RHOGVY) / prg_pl(n,k,l,I_RHOG)
          diag_pl(n,k,l,I_vz) = prg_pl(n,k,l,I_RHOGVZ) / prg_pl(n,k,l,I_RHOG)
          ein_pl (n,k,l)      = prg_pl(n,k,l,I_RHOGE ) / prg_pl(n,k,l,I_RHOG)
       enddo
       enddo
       enddo

       do iv = 1, TRC_vmax
       do l  = 1, ADM_lall_pl
       do k  = 1, ADM_kall
       do n  = 1, ADM_gall_pl
          diag_pl(n,k,l,DIAG_vmax0+iv) = prg_pl(n,k,l,PRG_vmax0+iv) / prg_pl(n,k,l,I_RHOG)
       enddo
       enddo
       enddo
       enddo

       !--- calculation of dry mass concentration
       call THRMDYN_qd_ijkl ( ADM_gall_pl, ADM_kall, ADM_lall_pl, & !--- [IN]
                              TRC_vmax, NQW_STR, NQW_END,         & !--- [IN]
                              qd_pl  (:,:,:),                     & !--- [OUT]
                              diag_pl(:,:,:,I_qstr:I_qend)        ) !--- [IN]

       !--- calculation of tem, pre
       call THRMDYN_tempre_ijkl( ADM_gall_pl, ADM_kall, ADM_lall_pl, & !--- [IN]
                                 TRC_vmax, NQW_STR, NQW_END,         & !--- [IN]
                                 diag_pl(:,:,:,I_tem),               & !--- [OUT]
                                 diag_pl(:,:,:,I_pre),               & !--- [OUT]
                                 ein_pl(:,:,:),                      & !--- [IN]
                                 rho_pl(:,:,:),                      & !--- [IN]
                                 qd_pl  (:,:,:),                     & !--- [IN]
                                 diag_pl(:,:,:,I_qstr:I_qend)        ) !--- [IN]

       do l = 1, ADM_lall_pl
          !------ interpolation of rhog_h
          do k = 2, ADM_kall
          do n = 1, ADM_gall_pl
             rhog_h_pl(n,k) = ( VMTR_C2Wfact_pl(n,k,1,l) * prg_pl(n,k  ,l,I_RHOG) &
                              + VMTR_C2Wfact_pl(n,k,2,l) * prg_pl(n,k-1,l,I_RHOG) )
          enddo
          enddo
          do n = 1, ADM_gall_pl
             rhog_h_pl(n,1) = rhog_h_pl(n,2)
          enddo

          do k = 1, ADM_kall
          do n = 1, ADM_gall_pl
             diag_pl(n,k,l,I_w) = prg_pl(n,k,l,I_RHOGW) / rhog_h_pl(n,k)
          enddo
          enddo
       enddo

    endif

    return
  end subroutine cnvvar_prg2diag

  !-----------------------------------------------------------------------------
  subroutine cnvvar_diag2prg( &
       prg,  prg_pl, &
       diag, diag_pl )
    use mod_adm, only: &
       ADM_prc_me,  &
       ADM_prc_pl,  &
       ADM_gall,    &
       ADM_gall_pl, &
       ADM_lall,    &
       ADM_lall_pl, &
       ADM_kall
    use mod_vmtr, only: &
       VMTR_GSGAM2,     &
       VMTR_GSGAM2_pl,  &
       VMTR_C2Wfact,    &
       VMTR_C2Wfact_pl
    use mod_runconf, only: &
       PRG_vmax,  &
       DIAG_vmax, &
       TRC_vmax,  &
       NQW_STR,   &
       NQW_END
    use mod_thrmdyn, only: &
       THRMDYN_qd_ijkl,  &
       THRMDYN_rho_ijkl, &
       THRMDYN_ein_ijkl
    implicit none

    real(8), intent(out) :: prg    (ADM_gall,   ADM_kall,ADM_lall,   PRG_vmax )
    real(8), intent(out) :: prg_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl,PRG_vmax )
    real(8), intent(in)  :: diag   (ADM_gall,   ADM_kall,ADM_lall,   DIAG_vmax)
    real(8), intent(in)  :: diag_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl,DIAG_vmax)

    real(8) :: qd       (ADM_gall,   ADM_kall,ADM_lall   )
    real(8) :: qd_pl    (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8) :: rho      (ADM_gall,   ADM_kall,ADM_lall   )
    real(8) :: rho_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8) :: ein      (ADM_gall,   ADM_kall,ADM_lall   )
    real(8) :: ein_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)

    real(8) :: rhog_h   (ADM_gall,   ADM_kall)
    real(8) :: rhog_h_pl(ADM_gall_pl,ADM_kall)

    integer :: n, k, l, iv
    !---------------------------------------------------------------------------

    !--- calculation of dry mass concentration
    call THRMDYN_qd_ijkl ( ADM_gall, ADM_kall, ADM_lall, & !--- [IN]
                           TRC_vmax, NQW_STR, NQW_END,   & !--- [IN]
                           qd  (:,:,:),                  & !--- [OUT]
                           diag(:,:,:,I_qstr:I_qend)     ) !--- [IN]

    !--- calculation  of density
    call THRMDYN_rho_ijkl( ADM_gall, ADM_kall, ADM_lall, & !--- [IN]
                           rho(:,:,:),                   & !--- [OUT]
                           diag(:,:,:,I_pre),            & !--- [IN]
                           diag(:,:,:,I_tem),            & !--- [IN]
                           qd  (:,:,:),                  & !--- [IN]
                           diag(:,:,:,I_qstr)            ) !--- [IN]

    !--- calculation of internal energy
    call THRMDYN_ein_ijkl( ADM_gall, ADM_kall, ADM_lall, & !--- [IN]
                           TRC_vmax, NQW_STR, NQW_END,   & !--- [IN]
                           ein(:,:,:),                   & !--- [OUT]
                           diag(:,:,:,I_tem),            & !--- [IN]
                           qd  (:,:,:),                  & !--- [IN]
                           diag(:,:,:,I_qstr:I_qend)     ) !--- [IN]

    do l = 1, ADM_lall
    do k = 1, ADM_kall
    do n = 1, ADM_gall
       prg(n,k,l,I_RHOG  ) = rho(n,k,l) * VMTR_GSGAM2(n,k,l)
       prg(n,k,l,I_RHOGVX) = prg(n,k,l,I_RHOG) * diag(n,k,l,I_vx)
       prg(n,k,l,I_RHOGVY) = prg(n,k,l,I_RHOG) * diag(n,k,l,I_vy)
       prg(n,k,l,I_RHOGVZ) = prg(n,k,l,I_RHOG) * diag(n,k,l,I_vz)
       prg(n,k,l,I_RHOGE ) = prg(n,k,l,I_RHOG) * ein (n,k,l)
    enddo
    enddo
    enddo

    do iv = 1, TRC_vmax
    do l  = 1, ADM_lall
    do k  = 1, ADM_kall
    do n  = 1, ADM_gall
       prg(n,k,l,PRG_vmax0+iv) = prg(n,k,l,I_RHOG) * diag(n,k,l,DIAG_vmax0+iv)
    enddo
    enddo
    enddo
    enddo

    do l = 1, ADM_lall
       !------ interpolation of rhog_h
       do k = 2, ADM_kall
       do n = 1, ADM_gall
          rhog_h(n,k) = ( VMTR_C2Wfact(n,k,1,l) * prg(n,k  ,l,I_RHOG) &
                        + VMTR_C2Wfact(n,k,2,l) * prg(n,k-1,l,I_RHOG) )
       enddo
       enddo
       do n = 1, ADM_gall
          rhog_h(n,1) = rhog_h(n,2)
       enddo

       do k = 1, ADM_kall
       do n = 1, ADM_gall
          prg(n,k,l,I_RHOGW) = rhog_h(n,k) * diag(n,k,l,I_w)
       enddo
       enddo
    enddo

    if ( ADM_prc_me == ADM_prc_pl ) then

       !--- calculation of dry mass concentration
       call THRMDYN_qd_ijkl ( ADM_gall_pl, ADM_kall, ADM_lall_pl, & !--- [IN]
                              TRC_vmax, NQW_STR, NQW_END,         & !--- [IN]
                              qd_pl  (:,:,:),                     & !--- [OUT]
                              diag_pl(:,:,:,I_qstr:I_qend)        ) !--- [IN]

       !--- calculation  of density
       call THRMDYN_rho_ijkl( ADM_gall_pl, ADM_kall, ADM_lall_pl, & !--- [IN]
                              rho_pl(:,:,:),                      & !--- [OUT]
                              diag_pl(:,:,:,I_pre),               & !--- [IN]
                              diag_pl(:,:,:,I_tem),               & !--- [IN]
                              qd_pl  (:,:,:),                     & !--- [IN]
                              diag_pl(:,:,:,I_qstr)               ) !--- [IN]

       !--- calculation of internal energy
       call THRMDYN_ein_ijkl( ADM_gall_pl, ADM_kall, ADM_lall_pl, & !--- [IN]
                              TRC_vmax, NQW_STR, NQW_END,         & !--- [IN]
                              ein_pl(:,:,:),                      & !--- [OUT]
                              diag_pl(:,:,:,I_tem),               & !--- [IN]
                              qd_pl  (:,:,:),                     & !--- [IN]
                              diag_pl(:,:,:,I_qstr:I_qend)        ) !--- [IN]

       do l = 1, ADM_lall_pl
       do k = 1, ADM_kall
       do n = 1, ADM_gall_pl
          prg_pl(n,k,l,I_RHOG  ) = rho_pl(n,k,l) * VMTR_GSGAM2_pl(n,k,l)
          prg_pl(n,k,l,I_RHOGVX) = prg_pl(n,k,l,I_RHOG) * diag_pl(n,k,l,I_vx)
          prg_pl(n,k,l,I_RHOGVY) = prg_pl(n,k,l,I_RHOG) * diag_pl(n,k,l,I_vy)
          prg_pl(n,k,l,I_RHOGVZ) = prg_pl(n,k,l,I_RHOG) * diag_pl(n,k,l,I_vz)
          prg_pl(n,k,l,I_RHOGE ) = prg_pl(n,k,l,I_RHOG) * ein_pl (n,k,l)
       enddo
       enddo
       enddo

       do iv = 1, TRC_vmax
       do l  = 1, ADM_lall_pl
       do k  = 1, ADM_kall
       do n  = 1, ADM_gall_pl
          prg_pl(n,k,l,PRG_vmax0+iv) = prg_pl(n,k,l,I_RHOG) * diag_pl(n,k,l,DIAG_vmax0+iv)
       enddo
       enddo
       enddo
       enddo

       do l = 1, ADM_lall_pl
          !------ interpolation of rhog_h
          do k = 2, ADM_kall
          do n = 1, ADM_gall_pl
             rhog_h_pl(n,k) = ( VMTR_C2Wfact_pl(n,k,1,l) * prg_pl(n,k  ,l,I_RHOG) &
                              + VMTR_C2Wfact_pl(n,k,2,l) * prg_pl(n,k-1,l,I_RHOG) )
          enddo
          enddo
          do n = 1, ADM_gall_pl
             rhog_h_pl(n,1) = rhog_h_pl(n,2)
          enddo

          do k = 1, ADM_kall
          do n = 1, ADM_gall_pl
             prg_pl(n,k,l,I_RHOGW) = rhog_h_pl(n,k) * diag_pl(n,k,l,I_w)
          enddo
          enddo
       enddo

    endif

    return
  end subroutine cnvvar_diag2prg

  !-----------------------------------------------------------------------------
  subroutine cnvvar_rhogkin( &
       rhog,    rhog_pl,   &
       rhogvx,  rhogvx_pl, &
       rhogvy,  rhogvy_pl, &
       rhogvz,  rhogvz_pl, &
       rhogw,   rhogw_pl,  &
       rhogkin, rhogkin_pl )
    use mod_adm, only: &
       ADM_prc_me,  &
       ADM_prc_pl,  &
       ADM_gall,    &
       ADM_gall_pl, &
       ADM_lall,    &
       ADM_lall_pl, &
       ADM_kall,    &
       ADM_kmax,    &
       ADM_kmin
    use mod_vmtr, only: &
       VMTR_C2Wfact,    &
       VMTR_C2Wfact_pl, &
       VMTR_W2Cfact,    &
       VMTR_W2Cfact_pl
    implicit none

    real(8), intent(in)  :: rhog      (ADM_gall,   ADM_kall,ADM_lall   ) ! rho X ( G^1/2 X gamma2 )
    real(8), intent(in)  :: rhog_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(in)  :: rhogvx    (ADM_gall,   ADM_kall,ADM_lall   ) ! rho X ( G^1/2 X gamma2 ) X vx
    real(8), intent(in)  :: rhogvx_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(in)  :: rhogvy    (ADM_gall,   ADM_kall,ADM_lall   ) ! rho X ( G^1/2 X gamma2 ) X vy
    real(8), intent(in)  :: rhogvy_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(in)  :: rhogvz    (ADM_gall,   ADM_kall,ADM_lall   ) ! rho X ( G^1/2 X gamma2 ) X vz
    real(8), intent(in)  :: rhogvz_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(in)  :: rhogw     (ADM_gall,   ADM_kall,ADM_lall   ) ! rho X ( G^1/2 X gamma2 ) X w
    real(8), intent(in)  :: rhogw_pl  (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(out) :: rhogkin   (ADM_gall,   ADM_kall,ADM_lall   ) ! rho X ( G^1/2 X gamma2 ) X kin
    real(8), intent(out) :: rhogkin_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)

    real(8) :: rhogkin_h   (ADM_gall,   ADM_kall) ! rho X ( G^1/2 X gamma2 ) X kin (horizontal)
    real(8) :: rhogkin_h_pl(ADM_gall_pl,ADM_kall)
    real(8) :: rhogkin_v   (ADM_gall,   ADM_kall) ! rho X ( G^1/2 X gamma2 ) X kin (vertical)
    real(8) :: rhogkin_v_pl(ADM_gall_pl,ADM_kall)

    integer :: g, k, l
    !---------------------------------------------------------------------------

    call DEBUG_rapstart('cnvvar_rhogkin')

    do l = 1, ADM_lall
       !--- horizontal kinetic energy
       do k = ADM_kmin, ADM_kmax
       do g = 1, ADM_gall
          rhogkin_h(g,k) = 0.5D0 * ( rhogvx(g,k,l) * rhogvx(g,k,l) &
                                   + rhogvy(g,k,l) * rhogvy(g,k,l) &
                                   + rhogvz(g,k,l) * rhogvz(g,k,l) ) / rhog(g,k,l)
       enddo
       enddo

       !--- vertical kinetic energy
       do k = ADM_kmin+1, ADM_kmax
       do g = 1, ADM_gall
          rhogkin_v(g,k) = 0.5D0 * ( rhogw(g,k,l) * rhogw(g,k,l) ) &
                         / ( VMTR_C2Wfact(g,k,1,l) * rhog(g,k  ,l) &
                           + VMTR_C2Wfact(g,k,2,l) * rhog(g,k-1,l) )
       enddo
       enddo
       rhogkin_v(:,ADM_kmin  ) = 0.D0
       rhogkin_v(:,ADM_kmax+1) = 0.D0

       !--- total kinetic energy
       do k = ADM_kmin, ADM_kmax
       do g = 1, ADM_gall
          rhogkin(g,k,l) = rhogkin_h(g,k)                             & ! horizontal
                         + ( VMTR_W2Cfact(g,k,1,l) * rhogkin_v(g,k+1) & ! vertical
                           + VMTR_W2Cfact(g,k,2,l) * rhogkin_v(g,k  ) )
       enddo
       enddo
       rhogkin(:,ADM_kmin-1,l) = 0.D0
       rhogkin(:,ADM_kmax+1,l) = 0.D0
    enddo

    if ( ADM_prc_me == ADM_prc_pl ) then
       do l = 1, ADM_lall_pl
          !--- horizontal kinetic energy
          do k = ADM_kmin, ADM_kmax
          do g = 1, ADM_gall_pl
             rhogkin_h_pl(g,k) = 0.5D0 * ( rhogvx_pl(g,k,l) * rhogvx_pl(g,k,l) &
                                         + rhogvy_pl(g,k,l) * rhogvy_pl(g,k,l) &
                                         + rhogvz_pl(g,k,l) * rhogvz_pl(g,k,l) ) / rhog_pl(g,k,l)
          enddo
          enddo

          !--- vertical kinetic energy
          do k = ADM_kmin+1, ADM_kmax
          do g = 1, ADM_gall_pl
             rhogkin_v_pl(g,k) = 0.5D0 * ( rhogw_pl(g,k,l) * rhogw_pl(g,k,l) ) &
                               / ( VMTR_C2Wfact_pl(g,k,1,l) * rhog_pl(g,k  ,l) &
                                 + VMTR_C2Wfact_pl(g,k,2,l) * rhog_pl(g,k-1,l) )
          enddo
          enddo
          rhogkin_v_pl(:,ADM_kmin  ) = 0.D0
          rhogkin_v_pl(:,ADM_kmax+1) = 0.D0

          !--- total kinetic energy
          do k = ADM_kmin, ADM_kmax
          do g = 1, ADM_gall_pl
             rhogkin_pl(g,k,l) = rhogkin_h_pl(g,k)                                & ! horizontal
                               + ( VMTR_W2Cfact_pl(g,k,1,l) * rhogkin_v_pl(g,k+1) & ! vertical
                                 + VMTR_W2Cfact_pl(g,k,2,l) * rhogkin_v_pl(g,k  ) )
          enddo
          enddo
          rhogkin_pl(:,ADM_kmin-1,l) = 0.D0
          rhogkin_pl(:,ADM_kmax+1,l) = 0.D0
       enddo
    endif

    call DEBUG_rapend('cnvvar_rhogkin')

    return
  end subroutine cnvvar_rhogkin

end module mod_cnvvar
!-------------------------------------------------------------------------------
