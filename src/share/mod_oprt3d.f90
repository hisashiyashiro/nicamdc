!-------------------------------------------------------------------------------
!>
!! 3D Operator module
!!
!! @par Description
!!         This module contains the subroutines for differential oeprators using vertical metrics.
!!
!! @author  H.Tomita
!!
!! @par History
!! @li      2004-02-17 (H.Tomita)    Imported from igdc-4.33
!! @li      2011-09-27 (T.Seiki)     merge optimization by RIST and M.Terai
!!
!<
module mod_oprt3d
  !-----------------------------------------------------------------------------
  !
  !++ Used modules
  !
  use mod_debug
  use mod_adm, only: &
     ADM_LOG_FID,    &
     TI  => ADM_TI,  &
     TJ  => ADM_TJ,  &
     AI  => ADM_AI,  &
     AIJ => ADM_AIJ, &
     AJ  => ADM_AJ,  &
     K0  => ADM_KNONE
  use mod_gmtr, only: &
     P_RAREA => GMTR_P_RAREA, &
     T_RAREA => GMTR_T_RAREA, &
     W1      => GMTR_T_W1,    &
     W2      => GMTR_T_W2,    &
     W3      => GMTR_T_W3,    &
     HNX     => GMTR_A_HNX,   &
     HNY     => GMTR_A_HNY,   &
     HNZ     => GMTR_A_HNZ,   &
     HTX     => GMTR_A_HTX,   &
     HTY     => GMTR_A_HTY,   &
     HTZ     => GMTR_A_HTZ,   &
     TNX     => GMTR_A_TNX,   &
     TNY     => GMTR_A_TNY,   &
     TNZ     => GMTR_A_TNZ,   &
     TN2X    => GMTR_A_TN2X,  &
     TN2Y    => GMTR_A_TN2Y,  &
     TN2Z    => GMTR_A_TN2Z
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: OPRT3D_divdamp

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
  subroutine OPRT3D_divdamp( &
       ddivdx, ddivdx_pl, &
       ddivdy, ddivdy_pl, &
       ddivdz, ddivdz_pl, &
       rhogvx, rhogvx_pl, &
       rhogvy, rhogvy_pl, &
       rhogvz, rhogvz_pl, &
       rhogw,  rhogw_pl   )
    use mod_adm, only: &
       ADM_have_pl,  &
       ADM_have_sgp, &
       ADM_lall,     &
       ADM_lall_pl,  &
       ADM_gall,     &
       ADM_gall_pl,  &
       ADM_kall,     &
       ADM_gall_1d,  &
       ADM_gmin,     &
       ADM_gmax,     &
       ADM_gslf_pl,  &
       ADM_gmin_pl,  &
       ADM_gmax_pl,  &
       ADM_kmin,     &
       ADM_kmax
    use mod_grd, only: &
       GRD_rdgz
    use mod_gmtr, only: &
       GMTR_P_var_pl, &
       GMTR_T_var_pl, &
       GMTR_A_var_pl
    use mod_oprt, only: &
       OPRT_nstart, &
       OPRT_nend,   &
       cinterp_TN,  &
       cinterp_HN,  &
       cinterp_TRA, &
       cinterp_PRA
    use mod_vmtr, only: &
       VMTR_RGAM,        &
       VMTR_RGAM_pl,     &
       VMTR_RGAMH,       &
       VMTR_RGAMH_pl,    &
       VMTR_RGSQRTH,     &
       VMTR_RGSQRTH_pl,  &
       VMTR_C2WfactGz,   &
       VMTR_C2WfactGz_pl
    implicit none

    real(8), intent(out) :: ddivdx   (ADM_gall   ,ADM_kall,ADM_lall   ) ! tendency
    real(8), intent(out) :: ddivdx_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(out) :: ddivdy   (ADM_gall   ,ADM_kall,ADM_lall   )
    real(8), intent(out) :: ddivdy_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(out) :: ddivdz   (ADM_gall   ,ADM_kall,ADM_lall   )
    real(8), intent(out) :: ddivdz_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(in)  :: rhogvx   (ADM_gall   ,ADM_kall,ADM_lall   ) ! rho*vx { gam2 x G^1/2 }
    real(8), intent(in)  :: rhogvx_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(in)  :: rhogvy   (ADM_gall   ,ADM_kall,ADM_lall   ) ! rho*vy { gam2 x G^1/2 }
    real(8), intent(in)  :: rhogvy_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(in)  :: rhogvz   (ADM_gall   ,ADM_kall,ADM_lall   ) ! rho*vz { gam2 x G^1/2 }
    real(8), intent(in)  :: rhogvz_pl(ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(8), intent(in)  :: rhogw    (ADM_gall   ,ADM_kall,ADM_lall   ) ! rho*w  { gam2 x G^1/2 }
    real(8), intent(in)  :: rhogw_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl)

    real(8) :: sclt         (ADM_gall   ,ADM_kall,TI:TJ) ! scalar on the hexagon vertex
    real(8) :: sclt_pl      (ADM_gall_pl,ADM_kall)
    real(8) :: sclt_rhogw
    real(8) :: sclt_rhogw_pl

    real(8) :: rhogvx_vm   (ADM_gall   ,ADM_kall) ! rho*vx / vertical metrics
    real(8) :: rhogvx_vm_pl(ADM_gall_pl,ADM_kall)
    real(8) :: rhogvy_vm   (ADM_gall   ,ADM_kall) ! rho*vy / vertical metrics
    real(8) :: rhogvy_vm_pl(ADM_gall_pl,ADM_kall)
    real(8) :: rhogvz_vm   (ADM_gall   ,ADM_kall) ! rho*vz / vertical metrics
    real(8) :: rhogvz_vm_pl(ADM_gall_pl,ADM_kall)
    real(8) :: rhogw_vm    (ADM_gall,   ADM_kall) ! rho*w  / vertical metrics
    real(8) :: rhogw_vm_pl (ADM_gall_pl,ADM_kall)

    integer :: nstart, nend
    integer :: ij
    integer :: ip1j, ijp1, ip1jp1
    integer :: im1j, ijm1, im1jm1

    integer :: g, k, l, v, n

    integer :: suf,i,j
    suf(i,j) = ADM_gall_1d * ((j)-1) + (i)
    !---------------------------------------------------------------------------

    call DEBUG_rapstart('OPRT3D_divdamp')

    do l = 1, ADM_lall
       do k = ADM_kmin+1, ADM_kmax
       do g = 1, ADM_gall
          rhogw_vm(g,k) = ( VMTR_C2WfactGz(1,g,k,l) * rhogvx(g,k  ,l) &
                          + VMTR_C2WfactGz(2,g,k,l) * rhogvx(g,k-1,l) &
                          + VMTR_C2WfactGz(3,g,k,l) * rhogvy(g,k  ,l) &
                          + VMTR_C2WfactGz(4,g,k,l) * rhogvy(g,k-1,l) &
                          + VMTR_C2WfactGz(5,g,k,l) * rhogvz(g,k  ,l) &
                          + VMTR_C2WfactGz(6,g,k,l) * rhogvz(g,k-1,l) &
                          ) * VMTR_RGAMH(g,k,l)                       & ! horizontal contribution
                        + rhogw(g,k,l) * VMTR_RGSQRTH(g,k,l)            ! vertical   contribution
       enddo
       enddo
       do g = 1, ADM_gall
          rhogw_vm(g,ADM_kmin  ) = 0.D0
          rhogw_vm(g,ADM_kmax+1) = 0.D0
       enddo

       do k = ADM_kmin, ADM_kmax
       do g = 1, ADM_gall
          rhogvx_vm(g,k) = rhogvx(g,k,l) * VMTR_RGAM(g,k,l)
          rhogvy_vm(g,k) = rhogvy(g,k,l) * VMTR_RGAM(g,k,l)
          rhogvz_vm(g,k) = rhogvz(g,k,l) * VMTR_RGAM(g,k,l)
       enddo
       enddo

       nstart = suf(ADM_gmin-1,ADM_gmin-1)
       nend   = suf(ADM_gmax,  ADM_gmax  )

       do k = ADM_kmin, ADM_kmax
       do n = nstart, nend
          ij     = n
          ip1j   = n + 1
          ip1jp1 = n + 1 + ADM_gall_1d

          sclt_rhogw = ( ( rhogw_vm(ij,k+1) + rhogw_vm(ip1j,k+1) + rhogw_vm(ip1jp1,k+1) ) &
                       - ( rhogw_vm(ij,k  ) + rhogw_vm(ip1j,k  ) + rhogw_vm(ip1jp1,k  ) ) &
                       ) / 3.D0 * GRD_rdgz(k)

          sclt(n,k,TI) = ( - (rhogvx_vm(ij    ,k)+rhogvx_vm(ip1j  ,k)) * cinterp_TN(AI ,1,ij  ,l) &
                           - (rhogvx_vm(ip1j  ,k)+rhogvx_vm(ip1jp1,k)) * cinterp_TN(AJ ,1,ip1j,l) &
                           + (rhogvx_vm(ip1jp1,k)+rhogvx_vm(ij    ,k)) * cinterp_TN(AIJ,1,ij  ,l) &
                           - (rhogvy_vm(ij    ,k)+rhogvy_vm(ip1j  ,k)) * cinterp_TN(AI ,2,ij  ,l) &
                           - (rhogvy_vm(ip1j  ,k)+rhogvy_vm(ip1jp1,k)) * cinterp_TN(AJ ,2,ip1j,l) &
                           + (rhogvy_vm(ip1jp1,k)+rhogvy_vm(ij    ,k)) * cinterp_TN(AIJ,2,ij  ,l) &
                           - (rhogvz_vm(ij    ,k)+rhogvz_vm(ip1j  ,k)) * cinterp_TN(AI ,3,ij  ,l) &
                           - (rhogvz_vm(ip1j  ,k)+rhogvz_vm(ip1jp1,k)) * cinterp_TN(AJ ,3,ip1j,l) &
                           + (rhogvz_vm(ip1jp1,k)+rhogvz_vm(ij    ,k)) * cinterp_TN(AIJ,3,ij  ,l) &
                         ) * 0.5D0 * cinterp_TRA(TI,ij,l) &
                       + sclt_rhogw
       enddo
       enddo

       do k = ADM_kmin, ADM_kmax
       do n = nstart, nend
          ij     = n
          ijp1   = n     + ADM_gall_1d
          ip1jp1 = n + 1 + ADM_gall_1d

          sclt_rhogw = ( ( rhogw_vm(ij,k+1) + rhogw_vm(ijp1,k+1) + rhogw_vm(ip1jp1,k+1) ) &
                       - ( rhogw_vm(ij,k  ) + rhogw_vm(ijp1,k  ) + rhogw_vm(ip1jp1,k  ) ) &
                       ) / 3.D0 * GRD_rdgz(k)

          sclt(n,k,TJ) = ( - (rhogvx_vm(ij    ,k)+rhogvx_vm(ip1jp1,k)) * cinterp_TN(AIJ,1,ij  ,l) &
                           + (rhogvx_vm(ip1jp1,k)+rhogvx_vm(ijp1  ,k)) * cinterp_TN(AI ,1,ijp1,l) &
                           + (rhogvx_vm(ijp1  ,k)+rhogvx_vm(ij    ,k)) * cinterp_TN(AJ ,1,ij  ,l) &
                           - (rhogvy_vm(ij    ,k)+rhogvy_vm(ip1jp1,k)) * cinterp_TN(AIJ,2,ij  ,l) &
                           + (rhogvy_vm(ip1jp1,k)+rhogvy_vm(ijp1  ,k)) * cinterp_TN(AI ,2,ijp1,l) &
                           + (rhogvy_vm(ijp1  ,k)+rhogvy_vm(ij    ,k)) * cinterp_TN(AJ ,2,ij  ,l) &
                           - (rhogvz_vm(ij    ,k)+rhogvz_vm(ip1jp1,k)) * cinterp_TN(AIJ,3,ij  ,l) &
                           + (rhogvz_vm(ip1jp1,k)+rhogvz_vm(ijp1  ,k)) * cinterp_TN(AI ,3,ijp1,l) &
                           + (rhogvz_vm(ijp1  ,k)+rhogvz_vm(ij    ,k)) * cinterp_TN(AJ ,3,ij  ,l) &
                         ) * 0.5D0 * cinterp_TRA(TJ,ij,l) &
                       + sclt_rhogw
       enddo
       enddo

       do k = ADM_kmin, ADM_kmax
       do n = OPRT_nstart, OPRT_nend
          ij     = n
          im1j   = n - 1
          ijm1   = n     - ADM_gall_1d
          im1jm1 = n - 1 - ADM_gall_1d

          ddivdx(n,k,l) = ( + ( sclt(ijm1,  k,TJ) + sclt(ij,    k,TI) ) * cinterp_HN(AI ,1,ij,    l) &
                            + ( sclt(ij,    k,TI) + sclt(ij,    k,TJ) ) * cinterp_HN(AIJ,1,ij,    l) &
                            + ( sclt(ij,    k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AJ ,1,ij,    l) &
                            - ( sclt(im1jm1,k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AI ,1,im1j,  l) &
                            - ( sclt(im1jm1,k,TI) + sclt(im1jm1,k,TJ) ) * cinterp_HN(AIJ,1,im1jm1,l) &
                            - ( sclt(ijm1  ,k,TJ) + sclt(im1jm1,k,TI) ) * cinterp_HN(AJ ,1,ijm1,  l) &
                          ) * 0.5D0 * cinterp_PRA(ij,l)

          ddivdy(n,k,l) = ( + ( sclt(ijm1,  k,TJ) + sclt(ij,    k,TI) ) * cinterp_HN(AI ,2,ij,    l) &
                            + ( sclt(ij,    k,TI) + sclt(ij,    k,TJ) ) * cinterp_HN(AIJ,2,ij,    l) &
                            + ( sclt(ij,    k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AJ ,2,ij,    l) &
                            - ( sclt(im1jm1,k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AI ,2,im1j,  l) &
                            - ( sclt(im1jm1,k,TI) + sclt(im1jm1,k,TJ) ) * cinterp_HN(AIJ,2,im1jm1,l) &
                            - ( sclt(ijm1  ,k,TJ) + sclt(im1jm1,k,TI) ) * cinterp_HN(AJ ,2,ijm1,  l) &
                          ) * 0.5D0 * cinterp_PRA(ij,l)

          ddivdz(n,k,l) = ( + ( sclt(ijm1,  k,TJ) + sclt(ij,    k,TI) ) * cinterp_HN(AI ,3,ij,    l) &
                            + ( sclt(ij,    k,TI) + sclt(ij,    k,TJ) ) * cinterp_HN(AIJ,3,ij,    l) &
                            + ( sclt(ij,    k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AJ ,3,ij,    l) &
                            - ( sclt(im1jm1,k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AI ,3,im1j,  l) &
                            - ( sclt(im1jm1,k,TI) + sclt(im1jm1,k,TJ) ) * cinterp_HN(AIJ,3,im1jm1,l) &
                            - ( sclt(ijm1  ,k,TJ) + sclt(im1jm1,k,TI) ) * cinterp_HN(AJ ,3,ijm1,  l) &
                          ) * 0.5D0 * cinterp_PRA(ij,l)
       enddo
       enddo

       if ( ADM_have_sgp(l) ) then
          n = suf(ADM_gmin,ADM_gmin)

          ij     = n
          im1j   = n - 1
          ijm1   = n     - ADM_gall_1d
          im1jm1 = n - 1 - ADM_gall_1d

          do k = ADM_kmin, ADM_kmax
             sclt(im1jm1,k,TI) = sclt(ijm1,k,TJ) ! copy

             ddivdx(n,k,l) = ( + ( sclt(ijm1,  k,TJ) + sclt(ij,    k,TI) ) * cinterp_HN(AI ,1,ij,    l) &
                               + ( sclt(ij,    k,TI) + sclt(ij,    k,TJ) ) * cinterp_HN(AIJ,1,ij,    l) &
                               + ( sclt(ij,    k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AJ ,1,ij,    l) &
                               - ( sclt(im1jm1,k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AI ,1,im1j,  l) &
                               - ( sclt(im1jm1,k,TI) + sclt(im1jm1,k,TJ) ) * cinterp_HN(AIJ,1,im1jm1,l) &
                             ) * 0.5D0 * cinterp_PRA(ij,l)

             ddivdy(n,k,l) = ( + ( sclt(ijm1,  k,TJ) + sclt(ij,    k,TI) ) * cinterp_HN(AI ,2,ij,    l) &
                               + ( sclt(ij,    k,TI) + sclt(ij,    k,TJ) ) * cinterp_HN(AIJ,2,ij,    l) &
                               + ( sclt(ij,    k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AJ ,2,ij,    l) &
                               - ( sclt(im1jm1,k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AI ,2,im1j,  l) &
                               - ( sclt(im1jm1,k,TI) + sclt(im1jm1,k,TJ) ) * cinterp_HN(AIJ,2,im1jm1,l) &
                             ) * 0.5D0 * cinterp_PRA(ij,l)

             ddivdz(n,k,l) = ( + ( sclt(ijm1,  k,TJ) + sclt(ij,    k,TI) ) * cinterp_HN(AI ,3,ij,    l) &
                               + ( sclt(ij,    k,TI) + sclt(ij,    k,TJ) ) * cinterp_HN(AIJ,3,ij,    l) &
                               + ( sclt(ij,    k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AJ ,3,ij,    l) &
                               - ( sclt(im1jm1,k,TJ) + sclt(im1j,  k,TI) ) * cinterp_HN(AI ,3,im1j,  l) &
                               - ( sclt(im1jm1,k,TI) + sclt(im1jm1,k,TJ) ) * cinterp_HN(AIJ,3,im1jm1,l) &
                             ) * 0.5D0 * cinterp_PRA(ij,l)
          enddo
       endif

       do g = 1, ADM_gall
          ddivdx(g,ADM_kmin-1,l) = 0.D0
          ddivdx(g,ADM_kmax+1,l) = 0.D0
          ddivdy(g,ADM_kmin-1,l) = 0.D0
          ddivdy(g,ADM_kmax+1,l) = 0.D0
          ddivdz(g,ADM_kmin-1,l) = 0.D0
          ddivdz(g,ADM_kmax+1,l) = 0.D0
       enddo
    enddo

    if ( ADM_have_pl ) then
       do l = 1, ADM_lall_pl
          do k = ADM_kmin+1, ADM_kmax
          do g = 1, ADM_gall_pl
             rhogw_vm_pl(g,k) = ( VMTR_C2WfactGz_pl(1,g,k,l) * rhogvx_pl(g,k  ,l) &
                                + VMTR_C2WfactGz_pl(2,g,k,l) * rhogvx_pl(g,k-1,l) &
                                + VMTR_C2WfactGz_pl(3,g,k,l) * rhogvy_pl(g,k  ,l) &
                                + VMTR_C2WfactGz_pl(4,g,k,l) * rhogvy_pl(g,k-1,l) &
                                + VMTR_C2WfactGz_pl(5,g,k,l) * rhogvz_pl(g,k  ,l) &
                                + VMTR_C2WfactGz_pl(6,g,k,l) * rhogvz_pl(g,k-1,l) &
                                ) * VMTR_RGAMH_pl(g,k,l)                          & ! horizontal contribution
                              + rhogw_pl(g,k,l) * VMTR_RGSQRTH_pl(g,k,l)            ! vertical   contribution
          enddo
          enddo
          do g = 1, ADM_gall_pl
             rhogw_vm_pl(g,ADM_kmin  ) = 0.D0
             rhogw_vm_pl(g,ADM_kmax+1) = 0.D0
          enddo

          do k = ADM_kmin, ADM_kmax
          do v = 1, ADM_gall_pl
             rhogvx_vm_pl(v,k) = rhogvx_pl(v,k,l) * VMTR_RGAM_pl(v,k,l)
             rhogvy_vm_pl(v,k) = rhogvy_pl(v,k,l) * VMTR_RGAM_pl(v,k,l)
             rhogvz_vm_pl(v,k) = rhogvz_pl(v,k,l) * VMTR_RGAM_pl(v,k,l)
          enddo
          enddo

          n = ADM_GSLF_PL

          do k = ADM_kmin, ADM_kmax
          do v = ADM_gmin_pl, ADM_gmax_pl
             ij   = v
             ijp1 = v + 1
             if( ijp1 > ADM_gmax_pl ) ijp1 = ADM_gmin_pl

             sclt_rhogw_pl = ( ( rhogw_vm_pl(n,k+1) + rhogw_vm_pl(ij,k+1) + rhogw_vm_pl(ijp1,k+1) ) &
                             - ( rhogw_vm_pl(n,k  ) + rhogw_vm_pl(ij,k  ) + rhogw_vm_pl(ijp1,k  ) ) &
                             ) / 3.D0 * GRD_rdgz(k)

             sclt_pl(v,k) = ( + ( rhogvx_vm_pl(n   ,k) + rhogvx_vm_pl(ij  ,k) ) * GMTR_A_var_pl(ij,  k0,l,TNX ) &
                              + ( rhogvy_vm_pl(n   ,k) + rhogvy_vm_pl(ij  ,k) ) * GMTR_A_var_pl(ij,  k0,l,TNY ) &
                              + ( rhogvz_vm_pl(n   ,k) + rhogvz_vm_pl(ij  ,k) ) * GMTR_A_var_pl(ij,  k0,l,TNZ ) &
                              + ( rhogvx_vm_pl(ij  ,k) + rhogvx_vm_pl(ijp1,k) ) * GMTR_A_var_pl(ij,  k0,l,TN2X) &
                              + ( rhogvy_vm_pl(ij  ,k) + rhogvy_vm_pl(ijp1,k) ) * GMTR_A_var_pl(ij,  k0,l,TN2Y) &
                              + ( rhogvz_vm_pl(ij  ,k) + rhogvz_vm_pl(ijp1,k) ) * GMTR_A_var_pl(ij,  k0,l,TN2Z) &
                              - ( rhogvx_vm_pl(ijp1,k) + rhogvx_vm_pl(n   ,k) ) * GMTR_A_var_pl(ijp1,k0,l,TNX ) &
                              - ( rhogvy_vm_pl(ijp1,k) + rhogvy_vm_pl(n   ,k) ) * GMTR_A_var_pl(ijp1,k0,l,TNY ) &
                              - ( rhogvz_vm_pl(ijp1,k) + rhogvz_vm_pl(n   ,k) ) * GMTR_A_var_pl(ijp1,k0,l,TNZ ) &
                            ) * 0.5D0 * GMTR_T_var_pl(ij,k0,l,T_RAREA) &
                          + sclt_rhogw_pl
          enddo
          enddo

          do k = ADM_kmin, ADM_kmax
             ddivdx_pl(n,k,l) = 0.D0
             ddivdy_pl(n,k,l) = 0.D0
             ddivdz_pl(n,k,l) = 0.D0

             do v = ADM_gmin_pl, ADM_gmax_pl
                ij   = v
                ijm1 = v - 1
                if( ijm1 < ADM_gmin_pl ) ijm1 = ADM_gmax_pl ! cyclic condition

                ddivdx_pl(n,k,l) = ddivdx_pl(n,k,l) + ( sclt_pl(ijm1,k) + sclt_pl(ij,k) ) * GMTR_A_var_pl(ij,k0,l,HNX)
                ddivdy_pl(n,k,l) = ddivdy_pl(n,k,l) + ( sclt_pl(ijm1,k) + sclt_pl(ij,k) ) * GMTR_A_var_pl(ij,k0,l,HNY)
                ddivdz_pl(n,k,l) = ddivdz_pl(n,k,l) + ( sclt_pl(ijm1,k) + sclt_pl(ij,k) ) * GMTR_A_var_pl(ij,k0,l,HNZ)
             enddo

             ddivdx_pl(n,k,l) = ddivdx_pl(n,k,l) * 0.5D0 * GMTR_P_var_pl(n,k0,l,P_RAREA)
             ddivdy_pl(n,k,l) = ddivdy_pl(n,k,l) * 0.5D0 * GMTR_P_var_pl(n,k0,l,P_RAREA)
             ddivdz_pl(n,k,l) = ddivdz_pl(n,k,l) * 0.5D0 * GMTR_P_var_pl(n,k0,l,P_RAREA)
          enddo

       enddo
    endif

    call DEBUG_rapend('OPRT3D_divdamp')

    return
  end subroutine OPRT3D_divdamp

end module mod_oprt3d
!-------------------------------------------------------------------------------
