subroutine flux_splitting_CH
use flow_general
implicit none

if(if_curve_grid) then
    call flux_splitting_CH_curve
else 
    call flux_splitting_CH_cartisian
endif

end subroutine


subroutine flux_splitting_CH_cartisian
use flow_general
implicit none
integer :: block_index

do block_index = 1,num_block
	call flux_splitting_CH_block(block_grid(block_index))
enddo
end subroutine

subroutine flux_splitting_CH_block(myblock)
use flow_general
use var_index
implicit none
type(block),intent(inout) :: myblock
double precision :: rho,u,v,p,alpha
integer :: index_i,index_j,index_eq
integer :: ni,nj,bfsize_i,bfsize_j

ni = myblock%ni
nj = myblock%nj
bfsize_i=myblock%bfsize_i
bfsize_j=myblock%bfsize_j

!$OMP PARALLEL DO default(shared) &
!$omp private(rho,u,p,alpha) &
!$omp private(index_i,index_j)
do index_j=1,nj
	do index_i=1,ni+2*bfsize_i
        rho   = myblock%prim(index_i,index_j+bfsize_j,prim_rho_index)
        u     = myblock%prim(index_i,index_j+bfsize_j,prim_u_index)
        p     = myblock%prim(index_i,index_j+bfsize_j,prim_p_index)
        alpha = myblock%prim(index_i,index_j+bfsize_j,prim_alpha_index)

        myblock%flux_xip(index_i,index_j,1)=0.5*((u+max_eig_i)*myblock%cons(index_i,index_j+bfsize_j,1))
        myblock%flux_xip(index_i,index_j,2)=0.5*((u+max_eig_i)*myblock%cons(index_i,index_j+bfsize_j,2)+p)
        myblock%flux_xip(index_i,index_j,3)=0.5*((u+max_eig_i)*myblock%cons(index_i,index_j+bfsize_j,3))
        myblock%flux_xip(index_i,index_j,4)=0.5*((u+max_eig_i)*myblock%cons(index_i,index_j+bfsize_j,4)+u*p)
        
        myblock%flux_xin(index_i,index_j,1)=0.5*((u-max_eig_i)*myblock%cons(index_i,index_j+bfsize_j,1))
        myblock%flux_xin(index_i,index_j,2)=0.5*((u-max_eig_i)*myblock%cons(index_i,index_j+bfsize_j,2)+p)
        myblock%flux_xin(index_i,index_j,3)=0.5*((u-max_eig_i)*myblock%cons(index_i,index_j+bfsize_j,3))
        myblock%flux_xin(index_i,index_j,4)=0.5*((u-max_eig_i)*myblock%cons(index_i,index_j+bfsize_j,4)+u*p)
    enddo
enddo
!$OMP END PARALLEL DO

call weno_character_5th_xi_p(myblock%prim,myblock%flux_xip,ni,nj,bfsize_i,bfsize_j,neq,myblock%h_xip)
call weno_character_5th_xi_n(myblock%prim,myblock%flux_xin,ni,nj,bfsize_i,bfsize_j,neq,myblock%h_xin)

!$OMP PARALLEL DO default(shared) &
!$omp private(rho,v,p,alpha) &
!$omp private(index_i,index_j)
do index_i=1,ni
	do index_j=1,nj+2*bfsize_j
        rho   = myblock%prim(index_i+bfsize_i,index_j,prim_rho_index)
        v     = myblock%prim(index_i+bfsize_i,index_j,prim_v_index)
        p     = myblock%prim(index_i+bfsize_i,index_j,prim_p_index)
        alpha = myblock%prim(index_i+bfsize_i,index_j,prim_alpha_index)
		
        myblock%flux_etap(index_j,index_i,1)=0.5*((v+max_eig_j)*myblock%cons(index_i+bfsize_i,index_j,1))
        myblock%flux_etap(index_j,index_i,2)=0.5*((v+max_eig_j)*myblock%cons(index_i+bfsize_i,index_j,2))
        myblock%flux_etap(index_j,index_i,3)=0.5*((v+max_eig_j)*myblock%cons(index_i+bfsize_i,index_j,3)+p)
        myblock%flux_etap(index_j,index_i,4)=0.5*((v+max_eig_j)*myblock%cons(index_i+bfsize_i,index_j,4)+v*p)
        
        myblock%flux_etan(index_j,index_i,1)=0.5*((v-max_eig_j)*myblock%cons(index_i+bfsize_i,index_j,1))
        myblock%flux_etan(index_j,index_i,2)=0.5*((v-max_eig_j)*myblock%cons(index_i+bfsize_i,index_j,2))
        myblock%flux_etan(index_j,index_i,3)=0.5*((v-max_eig_j)*myblock%cons(index_i+bfsize_i,index_j,3)+p)
        myblock%flux_etan(index_j,index_i,4)=0.5*((v-max_eig_j)*myblock%cons(index_i+bfsize_i,index_j,4)+v*p)
    enddo
enddo
!$OMP END PARALLEL DO

call weno_character_5th_eta_p(myblock%prim,myblock%flux_etap,ni,nj,bfsize_i,bfsize_j,neq,myblock%h_etap)
call weno_character_5th_eta_n(myblock%prim,myblock%flux_etan,ni,nj,bfsize_i,bfsize_j,neq,myblock%h_etan)

do index_eq=1,neq
    call sum_field(myblock%h_xi(:,:,index_eq),   &
                   myblock%h_xip(:,:,index_eq),  &
                   myblock%h_xin(:,:,index_eq),  &
                    1,                           &
                    ni+1,                        &
                    1,                           &
                    nj)
end do

do index_eq=1,neq
    call sum_field(myblock%h_eta(:,:,index_eq),  &
                   myblock%h_etap(:,:,index_eq), &
                   myblock%h_etan(:,:,index_eq), &
                    1,                           &
                    nj+1,                        &
                    1,                           &
                    ni)
end do

end subroutine flux_splitting_CH_block


subroutine flux_splitting_CH_curve
use flow_general
implicit none
integer :: block_index

end subroutine