subroutine Init_Metric
  use Metric_Var
  use Legendre
  use MD2D_Grid
  implicit none

  integer:: i,j,k

  call alloc_mem_metric_variables(PolyDegN_Max(1),&
                                  PolyDegN_Max(2),&
                                  TotNum_DM)

  ! compute dx/dxi
  do DDK=1,TotNum_DM
     ND1=PolyDegN_DM(1,DDK); 
     ND2=PolyDegN_DM(2,DDK); 

     
     dx1_dxi1(0:ND1,0:ND2,DDK)=&
          Matmul( Diff_xi1(0:ND1,0:ND1,ND1), x1(0:ND1,0:ND2,DDK))

     dx2_dxi1(0:ND1,0:ND2,DDK)=&
          Matmul( Diff_xi1(0:ND1,0:ND1,ND1), x2(0:ND1,0:ND2,DDK))

     dx1_dxi2(0:ND1,0:ND2,DDK)=&
          Matmul( x1(0:ND1,0:ND2,DDK) , Diff_xi2(0:ND2,0:ND2,ND2) )

     dx2_dxi2(0:ND1,0:ND2,DDK)=&
          Matmul( x2(0:ND1,0:ND2,DDK) , Diff_xi2(0:ND2,0:ND2,ND2) )

     ! compute Jacobin and dxi/dx 
     Jacobin(0:ND1,0:ND2,DDK) = &
        dx1_dxi1(0:ND1,0:ND2,DDK) * dx2_dxi2(0:ND1,0:ND2,DDK)   &
                              - &
        dx2_dxi1(0:ND1,0:ND2,DDK) * dx1_dxi2(0:ND1,0:ND2,DDK) 
     
     dxi1_dx1(0:ND1,0:ND2,DDK) = &
          dx2_dxi2(0:ND1,0:ND2,DDK)/Jacobin(0:ND1,0:ND2,DDK)

     dxi2_dx1(0:ND1,0:ND2,DDK) = &
         -dx2_dxi1(0:ND1,0:ND2,DDK)/Jacobin(0:ND1,0:ND2,DDK) 

     dxi1_dx2(0:ND1,0:ND2,DDK) = &
         -dx1_dxi2(0:ND1,0:ND2,DDK)/Jacobin(0:ND1,0:ND2,DDK) 

     dxi2_dx2(0:ND1,0:ND2,DDK) = &
          dx1_dxi1(0:ND1,0:ND2,DDK)/Jacobin(0:ND1,0:ND2,DDK) 


!!$        do j=0,ND2
!!$           do i=0,ND1
!!$              write(*,10000)i,j,&
!!$              dx1_dxi1(i,j,DDK), dx1_dxi2(i,j,DDK), dx2_dxi1(i,j,DDK), dx2_dxi2(i,j,DDK),&
!!$              Jacobin(i,j,DDK)
!!$10000         format(2i3,5f15.7)
!!$           enddo 
!!$        enddo
!!$     pause

  enddo


  ! we need to check wheather the computed jacobin is positive
  do DDK=1,TotNum_DM 
     ND1=PolyDegN_DM(1,DDK); 
     ND2=PolyDegN_DM(2,DDK); 

     do j=0,ND2
        do i=0,ND1 
           if (Jacobin(i,j,DDK) .le. 0.d0) then
              write(*,*)'Message from Metric_Pack.f90'
              write(*,*)'Jacobin is not positive:',i,j,Jacobin(i,j,DDK)
              write(*,*)'Abort!'
           endif
        enddo
     enddo
  enddo


  ! compute grid distortion for determining dt
  do DDK=1,TotNum_DM

     ND1=PolyDegN_DM(1,DDK); 
     ND2=PolyDegN_DM(2,DDK);

     ! compute local grid distance dxi1 and dxi2
     dxi1(0,0:ND2,DDK)=LGLCoord(1,ND1)-LGLCoord(0,ND1)
     do i=1,ND1-1
        dxi1(i,0:ND2,DDK)=(LGLCoord(i+1,ND1)-LGLCoord(i-1,ND1))/2.d0
     enddo
     dxi1(ND1,0:ND2,DDK)=LGLCoord(ND1,ND1)-LGLCoord(ND1-1,ND1)
     
     
     dxi2(0:ND1,0,DDK)=LGLCoord(1,ND2)-LGLCoord(0,ND2)
     do j=1,ND2-1
        dxi2(0:ND1,j,DDK)=(LGLCoord(j+1,ND2)-LGLCoord(j-1,ND2))/2.d0
     enddo
     dxi2(0:ND1,ND2,DDK)=LGLCoord(ND2,ND2)-LGLCoord(ND2-1,ND2)


     ! compute local grid distortion vector Cal X dot Cal X = dtrans

     ! Let 
     !           | grad xi1 | = ( |dxi1/dx1|, |dxi1/dx2| )
     !           | grad xi2 | = ( |dxi2/dx1|, |dxi2/dx2| )
     !           
     !           X = | grad xi1 |/dxi1 + | grad xi2 |/dxi2
     !           dtrans = sqrt( X dot X ) 

     dtrans(0:ND1,0:ND2,DDK) = dsqrt(&
       ( abs(dxi1_dx1(0:ND1,0:ND2,DDK)) / dxi1(0:ND1,0:ND2,DDK) + &
         abs(dxi2_dx1(0:ND1,0:ND2,DDK)) / dxi2(0:ND1,0:ND2,DDK) ) ** 2 &
      +( abs(dxi1_dx2(0:ND1,0:ND2,DDK)) / dxi1(0:ND1,0:ND2,DDK) + &
         abs(dxi2_dx2(0:ND1,0:ND2,DDK)) / dxi2(0:ND1,0:ND2,DDK) ) ** 2 )

  enddo

end subroutine Init_Metric



