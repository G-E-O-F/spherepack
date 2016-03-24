program test

    use, intrinsic :: iso_fortran_env, only: &
        wp     => REAL64, &
        ip     => INT32, &
        stdout => OUTPUT_UNIT

    use spherepack_wrapper_library, only: &
        SpherepackWrapper, &
        ThreeDimensionalVector, &
        assignment(=), &
        operator(*)

    ! Explicit typing only
    implicit none

    ! test all the procedures
    call test_all()

contains
    !
    
    !
    subroutine test_all()
        !
        !< Purpose:
        !
        !----------------------------------------------------------------------
        ! Dictionary: local variables
        !----------------------------------------------------------------------
        integer (ip), parameter    :: nlon = 36
        integer (ip), parameter    :: nlat = nlon/2 + 1
        type (SpherepackWrapper)    :: solver
        !----------------------------------------------------------------------

        ! Instantiate object
        call solver%create( nlat, nlon )

        write( stdout, '(A)' ) 'SPHEREPACK WRAPPER VALIDATION testS'
        write( stdout, '(A)' ) ' '
        write( stdout, '(A, I3, A, I3)' ) 'nlat = ', nlat, ' nlon = ', nlon

        ! test all the subroutines
        call test_scalar_analysis_and_synthesis( solver )
        call test_vector_analysis_and_synthesis( solver )
        call test_compute_surface_integral( solver )
        call test_invert_helmholtz( solver )
        call test_get_gradient( solver )
        call test_get_vorticity( solver )
        call test_get_rotation_operator( solver )

        ! disembody object
        call solver%destroy()

    end subroutine test_all
    !
    
    !
    subroutine test_scalar_analysis_and_synthesis( solver )
        !
        !< Purpose:
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        class (SpherepackWrapper), intent (in out)    :: solver
        !----------------------------------------------------------------------
        ! Dictionary: local variables
        !----------------------------------------------------------------------
        integer (ip)    :: k, l !! Counters
        real (wp)       :: real_error, complex_error
        real (wp)       :: original_function(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)       :: real_synthesized_function(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)       :: complex_synthesized_function(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        !----------------------------------------------------------------------

        associate( &
            nlat => solver%NUMBER_OF_LATITUDES, &
            nlon => solver%NUMBER_OF_LONGITUDES, &
            f    => original_function, &
            fr   => real_synthesized_function, &
            fc   => complex_synthesized_function &
            )

            ! Initialize array
            f = 0.0_wp

            do l = 1, nlon
                do k = 1, nlat
                    associate( u => solver%unit_vectors%radial( k, l) )
                        f(k, l) = exp(u%x + u%y + u%z)
                    end associate
                end do
            end do

            ! real case
            call solver%Perform_scalar_analysis( f )

            call solver%Perform_scalar_synthesis( fr )

            real_error = maxval( abs( f - fr ) )

            ! complex case
            call solver%Perform_complex_analysis( f )

            call solver% Perform_complex_synthesis( fc )

            complex_error = maxval( abs( f - fc ) )

        end associate

        ! Print errors to console
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) 'test_SCALAR_ANALYSIS_AND_SYNTHESIS'
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) 'f(theta, phi) = exp( sin(theta)cos(phi) + sin(theta)sin(phi) + cos(phi) )'
        write( stdout, '(A)' ) ' '
        write( stdout, '(A, ES23.16)' ) 'Real discretization error    =', real_error
        write( stdout, '(A, ES23.16)' ) 'Complex discretization error =', real_error
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) '*********************************************'

    end subroutine test_scalar_analysis_and_synthesis
    !
    
    !
    subroutine test_vector_analysis_and_synthesis( solver )
        !
        !< Purpose:
        !
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        class (SpherepackWrapper), intent (in out)     :: solver
        !----------------------------------------------------------------------
        ! Dictionary: local variables
        !----------------------------------------------------------------------
        integer (ip)    :: k, l !! Counters
        real (wp)       :: polar_error, azimuthal_error
        type (ThreeDimensionalVector) :: vector_field
        real (wp)       :: vector_function(3, solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)       :: original_polar_component(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)       :: original_azimuthal_component(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)       :: approximate_polar_component(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)       :: approximate_azimuthal_component(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        !----------------------------------------------------------------------

        associate( &
            nlat           => solver%NUMBER_OF_LATITUDES, &
            nlon           => solver%NUMBER_OF_LONGITUDES, &
            F              => vector_function, &
            F_theta        => original_polar_component, &
            F_phi          => original_azimuthal_component, &
            F_theta_approx => approximate_polar_component, &
            F_phi_approx   => approximate_azimuthal_component &
            )

            ! Initialize arrays
            F       = 0.0_wp
            F_theta = 0.0_wp
            F_phi   = 0.0_wp

            ! compute the vector field that gives rise original components
            do l = 1, nlon
                do k = 1, nlat

                    ! Convert array to vector
                    vector_field = [1.0e+3_wp, 1.0e+2_wp, 1.0e+1_wp]

                    associate( &
                        u     => solver%unit_vectors%radial( k, l), &
                        theta => solver%unit_vectors%polar(k, l), &
                        phi   => solver%unit_vectors%azimuthal(k, l) &
                        )

                        ! Set vector function
                        F(:, k, l) = vector_field

                         ! Set vector components
                        F_theta(k, l) = theta.dot.vector_field
                        F_phi(k, l)   = phi.dot.vector_field

                    end associate
                end do
            end do

            ! analyze the vector function
            call solver%Perform_vector_analysis( F )

            ! synthesize the function from the coefficients
            call solver%Perform_vector_synthesis( F_theta_approx, F_phi_approx )

            ! Set discretization errors
            polar_error     = maxval( abs( F_theta - F_theta_approx ))
            azimuthal_error = maxval( abs( F_phi   - F_phi_approx ))

        end associate

        ! Print the errors to console
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) 'test_VECTOR_ANALYSIS_AND_SYNTHESIS'
        write( stdout, '(A)' ) ' '
        write( stdout, '(A, ES23.16)' ) 'Discretization error in polar component     = ', polar_error
        write( stdout, '(A, ES23.16)' ) 'Discretization error in azimuthal component = ',  azimuthal_error
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) '*********************************************'


    end subroutine test_vector_analysis_and_synthesis
    !
    
    !
    subroutine test_compute_surface_integral( solver )
        !
        !< Purpose:
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        class (SpherepackWrapper), intent (in out)    :: solver
        !----------------------------------------------------------------------
        ! Dictionary: local variables
        !----------------------------------------------------------------------
        integer (ip)         :: k, l !! Counters
        real (wp)            :: scalar_function(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)            :: constant_function(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp), parameter :: FOUR_PI = 4.0_wp * acos( -1.0_wp )
        !----------------------------------------------------------------------

        associate( &
            nlat => solver%NUMBER_OF_LATITUDES, &
            nlon => solver%NUMBER_OF_LONGITUDES, &
            C    => constant_function, &
            f    => scalar_function &
            )

            ! Initialize the array
            C = 1.0_wp
            f = 0.0_wp

            ! set the scalar function
            do k = 1, nlat
                do l = 1, nlon

                    ! Convert array to vector
                    associate( x => solver%unit_vectors%radial(k, l)%x )

                        f(k, l) = exp( x )

                    end associate
                end do
            end do

            ! Compute discretization errors
            associate( &
                surface_area_error => abs( FOUR_PI - solver%Compute_surface_integral( C ) ), &
                integral_error     => abs( 14.768_wp - solver%Compute_surface_integral( f ) ) &
                )

                ! print the error to the console
                write( stdout, '(A)' ) ' '
                write( stdout, '(A)' ) 'test_COMPUTE_SURFACE_INTEGRAL'
                write( stdout, '(A)' ) ' '
                write( stdout, '(A)' ) '\int_(S^2) dS = \int_0^(2pi) \int_0^(pi) sin(theta) dtheta dphi '
                write( stdout, '(A)' ) ' '
                write( stdout, '(A, ES23.16)' ) 'Surface area error = ', surface_area_error
                write( stdout, '(A)' ) ' '
                write( stdout, '(A)' ) 'f(theta, phi) = exp( sin(theta)cos(phi)  )'
                write( stdout, '(A)' ) ' '
                write( stdout, '(A)' ) '\int_(S^2) f(theta, phi) dS '
                write( stdout, '(A)' ) ' '
                write( stdout, '(A, ES23.16)' ) 'Integral error = ', integral_error
                write( stdout, '(A)' ) ' '
                write( stdout, '(A)' ) '*********************************************'

            end associate
        end associate

    end subroutine test_Compute_surface_integral
    !
    
    !
    subroutine test_invert_helmholtz( solver )
        !
        !< Purpose:
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        class (SpherepackWrapper), intent (in out)    :: solver
        !----------------------------------------------------------------------
        ! Dictionary: local variables
        !----------------------------------------------------------------------
        integer (ip)     :: k, l !! Counters
        type (ThreeDimensionalVector)  :: u
        real (wp)        :: discretization_error
        real (wp)        :: exact_solution(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)        :: source_term(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)        :: approximate_solution(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        !----------------------------------------------------------------------

        associate( &
            nlat               => solver%NUMBER_OF_LATITUDES, &
            nlon               => solver%NUMBER_OF_LONGITUDES, &
            f                  => exact_solution, &
            f_approx           => approximate_solution, &
            rhs                => source_term, &
            HELMHOLTZ_CONSTANT => 1.0_wp &
            )

            ! initialize the scalar function and the exact solution
            do l = 1, nlon
                do k = 1, nlat

                    ! Convert array to vector
                    u = solver%unit_vectors%radial(k, l)

                    associate( &
                        x  => u%x, &
                        y  => u%y, &
                        z  => u%z, &
                        z2 => (u%z)**2 &
                        )

                        f(k, l) = (1.0_wp + x * y) * exp( z )

                        rhs(k, l) = &
                            -(x * y * ( z2 + 6.0_wp * (z + 1.0_wp)) &
                            + z * ( z + 2.0_wp)) * exp( z )

                    end associate
                end do
            end do

            ! Solve helmholtz's equation
            call solver%Invert_helmholtz( HELMHOLTZ_CONSTANT, rhs, f_approx)

            ! Set discretization error
            discretization_error = maxval( abs( f - f_approx ))

            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'test_INVERT_HELMHOLTZ'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'f(theta, phi) = [1 + sin^2(theta)sin(phi)cos(phi)] * exp( cos(phi) )'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16)' ) 'Discretization error = ', discretization_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) '*********************************************'

        end associate

    end subroutine test_invert_helmholtz
    !
    
    !
    subroutine test_get_gradient( solver )
        !
        !< Purpose:
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        class (SpherepackWrapper), intent (in out)    :: solver
        !----------------------------------------------------------------------
        ! Dictionary: local variables
        !----------------------------------------------------------------------
        integer (ip)     :: k, l !! Counters
        real (wp)        :: polar_error
        real (wp)        :: azimuthal_error
        type (ThreeDimensionalVector)  :: u
        real (wp)        :: scalar_function(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)        :: exact_polar_component(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)        :: exact_azimuthal_component(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)        :: approximate_polar_component(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)        :: approximate_azimuthal_component(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        !----------------------------------------------------------------------

        associate( &
            nlat           => solver%NUMBER_OF_LATITUDES, &
            nlon           => solver%NUMBER_OF_LONGITUDES, &
            f              => scalar_function, &
            f_theta        => exact_polar_component, &
            f_phi          => exact_azimuthal_component, &
            f_theta_approx => approximate_polar_component, &
            f_phi_approx   => approximate_azimuthal_component &
            )

            ! Initialize array
            f       = 0.0_wp
            f_theta = 0.0_wp
            f_phi   = 0.0_wp

            do l = 1, nlon
                do k = 1, nlat

                    outer: associate( &
                        sint => solver%trigonometric_functions%sint(k), &
                        cost => solver%trigonometric_functions%cost(k), &
                        sinp => solver%trigonometric_functions%sinp(l), &
                        cosp => solver%trigonometric_functions%cosp(l) &
                        )

                        u = solver%unit_vectors%radial(k, l)

                        f(k, l) = exp( u%x + u%y + u%z )

                        inner: associate( csc => 1.0_wp /sint)

                            f_theta(k, l) = &
                                f(k, l) * (cost * cosp &
                                - sint + cost * sinp)

                            f_phi(k, l) = &
                                f(k, l) * csc * (u%x - u%y)

                        end associate inner
                    end associate outer
                end do
            end do

            ! Calculate the gradient
            call solver%get_gradient( f, f_theta_approx, f_phi_approx )

            ! set errors
            polar_error     = maxval( abs( f_theta - f_theta_approx ))
            azimuthal_error = maxval( abs( f_phi   - f_phi_approx ) )

            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'test_get_GRADIENT'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'f(theta, phi) = exp( sin(theta)cos(phi) + sin(theta)sin(phi) + cos(phi) )'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16)' ) 'Discretization error polar component     = ', polar_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16)' ) 'Discretization error azimuthal component = ', azimuthal_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) '*********************************************'

        end associate

    end subroutine test_get_gradient
    !
    
    !
    subroutine test_get_vorticity( solver )
        !
        !< Purpose:
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        class (SpherepackWrapper), intent (in out)  :: solver
        !----------------------------------------------------------------------
        ! Dictionary: local variables
        !----------------------------------------------------------------------
        integer (ip)     :: k, l !! Counters
        type (ThreeDimensionalVector)  :: u
        type (ThreeDimensionalVector)  :: omega
        type (ThreeDimensionalVector)  :: rotation_operator
        real (wp)        :: discretization_error
        real (wp)        :: vector_function(3, solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)        :: exact_vorticity(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)        :: approximate_vorticity(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        !----------------------------------------------------------------------

        associate( &
            nlat     => solver%NUMBER_OF_LATITUDES, &
            nlon     => solver%NUMBER_OF_LONGITUDES, &
            F        => vector_function, &
            V        => exact_vorticity, &
            V_approx => approximate_vorticity &
            )

            ! initialize arrays
            F  = 0.0_wp
            V     = 0.0_wp
            omega = ThreeDimensionalVector( x = 1.0e+1_wp, y = 1.0e+2_wp, z = 1.0e+3_wp )

            do l = 1, nlon
                do k = 1, nlat

                    u = solver%unit_vectors%radial(k, l)

                    outer: associate( &
                        sint => solver%trigonometric_functions%sint(k), &
                        cost => solver%trigonometric_functions%cost(k), &
                        sinp => solver%trigonometric_functions%sinp(l), &
                        cosp => solver%trigonometric_functions%cosp(l), &
                        sf    => exp(u%x + u%y + u%z) & ! Scalar function
                        )

                        F(:, k, l) = omega * sf

                        inner: associate( &
                            D_theta => (cost * cosp  + cost * sinp - sint ) * sf, &
                            D_phi   => (u%x - u%y) * sf, &
                            cot     => 1.0_wp/ tan(solver%grid%latitudes(k)) &
                            )

                            rotation_operator = &
                                [ -sinp * D_theta - cosp * cot * D_phi, &
                                cosp * D_theta - sinp * cot * D_phi, &
                                D_phi ]

                            V(k, l) = rotation_operator.dot.omega

                        end associate inner
                    end associate outer
                end do
            end do

            ! check if the work space arrays are set up for the (real) vector transform
            call solver%get_vorticity( F, V_approx )

            ! set error
            discretization_error = maxval(abs( V - V_approx ))

            ! print error to console
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'test_get_VORTICITY'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16)' ) 'Discretization error = ',  discretization_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) '*********************************************'

        end associate

    end subroutine test_get_vorticity
    !
    
    !
    subroutine test_get_rotation_operator( solver )
        !
        !< Purpose:
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        class (SpherepackWrapper), intent (in out)    :: solver
        !----------------------------------------------------------------------
        ! Dictionary: local variables
        !----------------------------------------------------------------------
        integer (ip)    :: k, l !! Counters
        real (wp)       :: discretization_error
        type (ThreeDimensionalVector) :: u
        real (wp)       :: exact_rotation(3, solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)       :: approximate_rotation(3, solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        real (wp)       :: scalar_function(solver%NUMBER_OF_LATITUDES, solver%NUMBER_OF_LONGITUDES)
        !----------------------------------------------------------------------

        ! Set constants
        associate( &
            nlat      => solver%NUMBER_OF_LATITUDES, &
            nlon      => solver%NUMBER_OF_LONGITUDES, &
            f         => scalar_function, &
            Rf        => exact_rotation, &
            Rf_approx => approximate_rotation &
            )

            ! initialize arrays
            f  = 0.0_wp
            Rf = 0.0_wp

            do l = 1, nlon
                do k = 1, nlat

                    u = solver%unit_vectors%radial( k, l)

                    f(k, l) = exp(u%x + u%y + u%z)

                    outer: associate( &
                        sint  => solver%trigonometric_functions%sint(k), &
                        cost  => solver%trigonometric_functions%cost(k), &
                        sinp  => solver%trigonometric_functions%sinp(l), &
                        cosp  => solver%trigonometric_functions%cosp(l), &
                        theta => solver%grid%latitudes(k) &
                        )

                        inner: associate( &
                            D_theta => ( cost * cosp + cost * sinp - sint ) * f(k, l), &
                            D_phi   => ( u%x - u%y ) * f(k, l), &
                            cot     => 1.0_wp/ tan(theta) &
                            )

                            Rf(1, k, l) = -sinp * D_theta - cosp * cot * D_phi

                            Rf(2, k, l) = cosp * D_theta - sinp * cot * D_phi

                            Rf(3, k, l) = D_phi

                        end associate inner
                    end associate outer
                end do
            end do

            ! compute the rotation operator applied to the scalar function
            call solver%get_rotation_operator( f, Rf_approx )

            ! set error
            discretization_error = maxval( abs( Rf - Rf_approx ) )

            ! print error to console
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'test_get_ROTATION_OPERATOR'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16 )' ) 'Discretization error = ', discretization_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) '*********************************************'

        end associate

    end subroutine test_get_rotation_operator
    !
    
    !
end program test