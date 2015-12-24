program test

    use, intrinsic :: iso_fortran_env, only: &
        WP     => REAL64, &
        IP     => INT32, &
        stdout => OUTPUT_UNIT

    use spherepack_wrapper_mod, only: &
        sphere_t, &
        vector_t, &
        assignment(=), &
        operator(*)

    ! Explicit typing only
    implicit none

    ! Test all the procedures
    call Test_all()

contains
    !
    !*****************************************************************************************
    !
    subroutine Test_all()
        !
        !< Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP), parameter    :: nlon = 36
        integer (IP), parameter    :: nlat = nlon/2 + 1
        type (sphere_t)            :: this
        !--------------------------------------------------------------------------------

        ! Create sphere object
        call this%Create( nlat, nlon )

        write( stdout, '(A)' ) 'SPHEREPACK WRAPPER VALIDATION TESTS'
        write( stdout, '(A)' ) ' '
        write( stdout, '(A, I3, A, I3)' ) 'nlat = ', nlat, ' nlon = ', nlon

        ! Test all the subroutines
        call Test_scalar_analysis_and_synthesis( this )
        call Test_vector_analysis_and_synthesis( this )
        call Test_compute_surface_integral( this )
        call Test_invert_helmholtz( this )
        call Test_get_gradient( this )
        call Test_get_vorticity( this )
        call Test_get_rotation_operator( this )

        ! Destroy sphere object
        call this%Destroy()

    end subroutine Test_all
    !
    !*****************************************************************************************
    !
    subroutine Test_scalar_analysis_and_synthesis( this )
        !
        !< Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)    :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)    :: k, l !! Counters
        real (WP)       :: real_error, complex_error
        type (vector_t) :: u
        real (WP)       :: original_function(this%NLAT, this%NLON)
        real (WP)       :: real_synthesized_function(this%NLAT, this%NLON)
        real (WP)       :: complex_synthesized_function(this%NLAT, this%NLON)
        !--------------------------------------------------------------------------------

        associate( &
            nlat => this%NLAT, &
            nlon => this%NLON, &
            f    => original_function, &
            fr   => real_synthesized_function, &
            fc   => complex_synthesized_function &
            )

            ! Initialize array
            f = 0.0_WP

            do l = 1, nlon
                do k = 1, nlat

                    u = this%radial_unit_vector(:, k, l)

                    f(k, l) = exp(u%x + u%y + u%z)

                end do
            end do

            ! real case
            call this%Perform_scalar_analysis( f )

            call this%Perform_scalar_synthesis( fr )

            real_error = maxval( abs( f - fr ) )

            ! complex case
            call this%Perform_complex_analysis( f )

            call this% Perform_complex_synthesis( fc )

            complex_error = maxval( abs( f - fc ) )

        end associate

        ! Print errors to console
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) 'TEST_SCALAR_ANALYSIS_AND_SYNTHESIS'
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) 'f(theta, phi) = exp( sin(theta)cos(phi) + sin(theta)sin(phi) + cos(phi) )'
        write( stdout, '(A)' ) ' '
        write( stdout, '(A, ES23.16)' ) 'Real discretization error    =', real_error
        write( stdout, '(A, ES23.16)' ) 'Complex discretization error =', real_error
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) '*********************************************'

    end subroutine Test_scalar_analysis_and_synthesis
    !
    !*****************************************************************************************
    !
    subroutine Test_vector_analysis_and_synthesis( this )
        !
        !< Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)     :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)    :: k, l !! Counters
        real (WP)       :: polar_error, azimuthal_error
        type (vector_t) :: u, phi, theta, vector_field
        real (WP)       :: vector_function(3, this%NLAT, this%NLON)
        real (WP)       :: original_polar_component(this%NLAT, this%NLON)
        real (WP)       :: original_azimuthal_component(this%NLAT, this%NLON)
        real (WP)       :: approximate_polar_component(this%NLAT, this%NLON)
        real (WP)       :: approximate_azimuthal_component(this%NLAT, this%NLON)
        !--------------------------------------------------------------------------------

        associate( &
            nlat           => this%NLAT, &
            nlon           => this%NLON, &
            F              => vector_function, &
            F_theta        => original_polar_component, &
            F_phi          => original_azimuthal_component, &
            F_theta_approx => approximate_polar_component, &
            F_phi_approx   => approximate_azimuthal_component &
            )

            ! Initialize arrays
            F       = 0.0_WP
            F_theta = 0.0_WP
            F_phi   = 0.0_WP

            ! compute the vector field that gives rise original components
            do l = 1, nlon
                do k = 1, nlat

                    ! Convert arrays to vectors
                    u            = this%radial_unit_vector(:, k, l)
                    theta        = this%polar_unit_vector(:, k, l)
                    phi          = this%azimuthal_unit_vector(:, k, l)
                    vector_field = [1.0E+3_WP, 1.0E+2_WP, 1.0E+1_WP]

                    ! Set vector function
                    F(:, k, l) = vector_field

                     ! Set vector components
                    F_theta(k, l) = theta.dot.vector_field
                    F_phi(k, l)   = phi.dot.vector_field

                end do
            end do

            ! analyze the vector function
            call this%Perform_vector_analysis( F )

            ! synthesize the function from the coefficients
            call this%Perform_vector_synthesis( F_theta_approx, F_phi_approx )

            ! Set discretization errors
            polar_error     = maxval( abs( F_theta - F_theta_approx ))
            azimuthal_error = maxval( abs( F_phi   - F_phi_approx ))

        end associate

        ! Print the errors to console
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) 'TEST_VECTOR_ANALYSIS_AND_SYNTHESIS'
        write( stdout, '(A)' ) ' '
        write( stdout, '(A, ES23.16)' ) 'Discretization error in polar component     = ', polar_error
        write( stdout, '(A, ES23.16)' ) 'Discretization error in azimuthal component = ',  azimuthal_error
        write( stdout, '(A)' ) ' '
        write( stdout, '(A)' ) '*********************************************'


    end subroutine Test_vector_analysis_and_synthesis
    !
    !*****************************************************************************************
    !
    subroutine Test_compute_surface_integral( this )
        !
        !< Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)    :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)         :: k, l !! Counters
        real (WP)            :: scalar_function(this%NLAT, this%NLON)
        real (WP)            :: constant_function(this%NLAT, this%NLON)
        real (WP), parameter :: FOUR_PI = 4.0_WP * acos( -1.0_WP )
        !--------------------------------------------------------------------------------

        associate( &
            nlat => this%NLAT, &
            nlon => this%NLON, &
            C    => constant_function, &
            f    => scalar_function &
            )

            ! Initialize the array
            C = 1.0_WP
            f = 0.0_WP

            ! set the scalar function
            do k = 1, nlat
                do l = 1, nlon

                    ! Convert array to vector
                    associate( x => this%radial_unit_vector(1, k, l) )

                        f(k, l) = exp( x )

                    end associate
                end do
            end do

            ! Compute discretization errors
            associate( &
                surface_area_error => abs( FOUR_PI - this%Compute_surface_integral( C ) ), &
                integral_error     => abs( 14.768_WP - this%Compute_surface_integral( f ) ) &
                )

                ! print the error to the console
                write( stdout, '(A)' ) ' '
                write( stdout, '(A)' ) 'TEST_COMPUTE_SURFACE_INTEGRAL'
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

    end subroutine Test_Compute_surface_integral
    !
    !*****************************************************************************************
    !
    subroutine Test_invert_helmholtz( this )
        !
        !< Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)    :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)     :: k, l !! Counters
        type (vector_t)  :: u
        real (WP)        :: discretization_error
        real (WP)        :: exact_solution(this%NLAT, this%NLON)
        real (WP)        :: source_term(this%NLAT, this%NLON)
        real (WP)        :: approximate_solution(this%NLAT, this%NLON)
        !--------------------------------------------------------------------------------

        associate( &
            nlat               => this%NLAT, &
            nlon               => this%NLON, &
            f                  => exact_solution, &
            f_approx           => approximate_solution, &
            rhs                => source_term, &
            HELMHOLTZ_CONSTANT => 1.0_WP &
            )

            ! initialize the scalar function and the exact solution
            do l = 1, nlon
                do k = 1, nlat

                    ! Convert array to vector
                    u = this%radial_unit_vector(:, k, l)

                    associate( &
                        x  => u%x, &
                        y  => u%y, &
                        z  => u%z, &
                        z2 => (u%z)**2 &
                        )

                        f(k, l) = (1.0_WP + x * y) * exp( z )

                        rhs(k, l) = &
                            -(x * y * ( z2 + 6.0_WP * (z + 1.0_WP)) &
                            + z * ( z + 2.0_WP)) * exp( z )

                    end associate
                end do
            end do

            ! Solve helmholtz's equation
            call this%Invert_helmholtz( HELMHOLTZ_CONSTANT, rhs, f_approx)

            ! Set discretization error
            discretization_error = maxval( abs( f - f_approx ))

            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'TEST_INVERT_HELMHOLTZ'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'f(theta, phi) = [1 + sin^2(theta)sin(phi)cos(phi)] * exp( cos(phi) )'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16)' ) 'Discretization error = ', discretization_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) '*********************************************'

        end associate

    end subroutine Test_invert_helmholtz
    !
    !*****************************************************************************************
    !
    subroutine Test_get_gradient( this )
        !
        !< Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)    :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)     :: k, l !! Counters
        real (WP)        :: polar_error
        real (WP)        :: azimuthal_error
        type (vector_t)  :: u
        real (WP)        :: scalar_function(this%NLAT, this%NLON)
        real (WP)        :: exact_polar_component(this%NLAT, this%NLON)
        real (WP)        :: exact_azimuthal_component(this%NLAT, this%NLON)
        real (WP)        :: approximate_polar_component(this%NLAT, this%NLON)
        real (WP)        :: approximate_azimuthal_component(this%NLAT, this%NLON)
        !--------------------------------------------------------------------------------

        associate( &
            nlat           => this%NLAT, &
            nlon           => this%NLON, &
            f              => scalar_function, &
            f_theta        => exact_polar_component, &
            f_phi          => exact_azimuthal_component, &
            f_theta_approx => approximate_polar_component, &
            f_phi_approx   => approximate_azimuthal_component &
            )

            ! Initialize array
            f       = 0.0_WP
            f_theta = 0.0_WP
            f_phi   = 0.0_WP

            do l = 1, nlon
                do k = 1, nlat

                    outer: associate( &
                        sint => this%sint(k), &
                        cost => this%cost(k), &
                        sinp => this%sinp(l), &
                        cosp => this%cosp(l) &
                        )

                        u = this%radial_unit_vector(:, k, l)

                        f(k, l) = exp( u%x + u%y + u%z )

                        inner: associate( csc => 1.0_WP /sint)

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
            call this%Get_gradient( f, f_theta_approx, f_phi_approx )

            ! set errors
            polar_error     = maxval( abs( f_theta - f_theta_approx ))
            azimuthal_error = maxval( abs( f_phi   - f_phi_approx ) )

            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'TEST_GET_GRADIENT'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'f(theta, phi) = exp( sin(theta)cos(phi) + sin(theta)sin(phi) + cos(phi) )'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16)' ) 'Discretization error polar component     = ', polar_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16)' ) 'Discretization error azimuthal component = ', azimuthal_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) '*********************************************'

        end associate

    end subroutine Test_get_gradient
    !
    !*****************************************************************************************
    !
    subroutine Test_get_vorticity( this )
        !
        !< Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)  :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)     :: k, l !! Counters
        type (vector_t)  :: u
        type (vector_t)  :: omega
        type (vector_t)  :: rotation_operator
        real (WP)        :: discretization_error
        real (WP)        :: vector_function(3, this%NLAT, this%NLON)
        real (WP)        :: exact_vorticity(this%NLAT, this%NLON)
        real (WP)        :: approximate_vorticity(this%NLAT, this%NLON)
        !--------------------------------------------------------------------------------

        associate( &
            nlat     => this%NLAT, &
            nlon     => this%NLON, &
            F        => vector_function, &
            V        => exact_vorticity, &
            V_approx => approximate_vorticity &
            )

            ! initialize arrays
            F  = 0.0_WP
            V     = 0.0_WP
            omega = vector_t( x = 1.0E+1_WP, y = 1.0E+2_WP, z = 1.0E+3_WP )

            do l = 1, nlon
                do k = 1, nlat

                    u = this%radial_unit_vector(:, k, l)

                    outer: associate( &
                        sint => this%sint(k), &
                        cost => this%cost(k), &
                        sinp => this%sinp(l), &
                        cosp => this%cosp(l), &
                        sf    => exp(u%x + u%y + u%z) & ! Scalar function
                        )

                        F(:, k, l) = omega * sf

                        inner: associate( &
                            D_theta => (cost * cosp  + cost * sinp - sint ) * sf, &
                            D_phi   => (u%x - u%y) * sf, &
                            cot     => 1.0_WP/ tan(this%grid%latitudes(k)) &
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
            call this%Get_vorticity( F, V_approx )

            ! set error
            discretization_error = maxval(abs( V - V_approx ))

            ! print error to console
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'TEST_GET_VORTICITY'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16)' ) 'Discretization error = ',  discretization_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) '*********************************************'

        end associate

    end subroutine Test_get_vorticity
    !
    !*****************************************************************************************
    !
    subroutine Test_get_rotation_operator( this )
        !
        !< Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)    :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)    :: k, l !! Counters
        real (WP)       :: discretization_error
        type (vector_t) :: u
        real (WP)       :: exact_rotation(3, this%NLAT, this%NLON)
        real (WP)       :: approximate_rotation(3, this%NLAT, this%NLON)
        real (WP)       :: scalar_function(this%NLAT, this%NLON)
        !--------------------------------------------------------------------------------

        ! Set constants
        associate( &
            nlat      => this%NLAT, &
            nlon      => this%NLON, &
            f         => scalar_function, &
            Rf        => exact_rotation, &
            Rf_approx => approximate_rotation &
            )

            ! initialize arrays
            f  = 0.0_WP
            Rf = 0.0_WP

            do l = 1, nlon
                do k = 1, nlat

                    u = this%radial_unit_vector(:, k, l)

                    f(k, l) = exp(u%x + u%y + u%z)

                    outer: associate( &
                        sint  => this%sint(k), &
                        cost  => this%cost(k), &
                        sinp  => this%sinp(l), &
                        cosp  => this%cosp(l), &
                        theta => this%grid%latitudes(k) &
                        )

                        inner: associate( &
                            D_theta => ( cost * cosp + cost * sinp - sint ) * f(k, l), &
                            D_phi   => ( u%x - u%y ) * f(k, l), &
                            cot     => 1.0_WP/ tan(theta) &
                            )

                            Rf(1, k, l) = -sinp * D_theta - cosp * cot * D_phi

                            Rf(2, k, l) = cosp * D_theta - sinp * cot * D_phi

                            Rf(3, k, l) = D_phi

                        end associate inner
                    end associate outer
                end do
            end do

            ! compute the rotation operator applied to the scalar function
            call this%Get_rotation_operator( f, Rf_approx )

            ! set error
            discretization_error = maxval( abs( Rf - Rf_approx ) )

            ! print error to console
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) 'TEST_GET_ROTATION_OPERATOR'
            write( stdout, '(A)' ) ' '
            write( stdout, '(A, ES23.16 )' ) 'Discretization error = ', discretization_error
            write( stdout, '(A)' ) ' '
            write( stdout, '(A)' ) '*********************************************'

        end associate

    end subroutine Test_get_rotation_operator
    !
    !*****************************************************************************************
    !
end program test
