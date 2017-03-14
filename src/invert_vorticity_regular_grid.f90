!
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!     *                                                               *
!     *                  copyright (c) 1998 by UCAR                   *
!     *                                                               *
!     *       University Corporation for Atmospheric Research         *
!     *                                                               *
!     *                      all rights reserved                      *
!     *                                                               *
!     *                         Spherepack                            *
!     *                                                               *
!     *       A Package of Fortran Subroutines and Programs           *
!     *                                                               *
!     *              for Modeling Geophysical Processes               *
!     *                                                               *
!     *                             by                                *
!     *                                                               *
!     *                  John Adams and Paul Swarztrauber             *
!     *                                                               *
!     *                             of                                *
!     *                                                               *
!     *         the National Center for Atmospheric Research          *
!     *                                                               *
!     *                Boulder, Colorado  (80307)  U.S.A.             *
!     *                                                               *
!     *                   which is sponsored by                       *
!     *                                                               *
!     *              the National Science Foundation                  *
!     *                                                               *
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!
submodule(vorticity_routines) invert_vorticity_regular_grid

contains

    !     subroutine ivrtec(nlat, nlon, isym, nt, v, w, idvw, jdvw, a, b, mdab, ndab,
    !                       wvhsec, pertrb, ierror)
    !
    !     given the scalar spherical harmonic coefficients a and b, precomputed
    !     by subroutine shaec for a scalar array vort, subroutine ivrtec computes
    !     a divergence free vector field (v, w) whose vorticity is vt - pertrb.
    !     w is the east longitude component and v is the colatitudinal component.
    !     pertrb is a constant which must be subtracted from vort for (v, w) to
    !     exist (see the description of pertrb below).  usually pertrb is zero
    !     or small relative to vort.  the divergence of (v, w), as computed by
    !     ivrtec, is the zero scalar field.  i.e., v(i, j) and w(i, j) are the
    !     colaatitudinal and east longitude velocity components at colatitude
    !
    !            theta(i) = (i-1)*pi/(nlat-1)
    !
    !     and longitude
    !
    !            lambda(j) = (j-1)*2*pi/nlon.
    !
    !     the
    !
    !            vorticity(v(i, j), w(i, j))
    !
    !         =  [-dv/dlambda + d(sint*w)/dtheta]/sint
    !
    !         =  vort(i, j) - pertrb
    !
    !     and
    !
    !            divergence(v(i, j), w(i, j))
    !
    !         =  [d(sint*v)/dtheta + dw/dlambda]/sint
    !
    !         =  0.0
    !
    !     where sint = sin(theta(i)).  required associated legendre polynomials
    !     are recomputed rather than stored as they are in subroutine ivrtes.
    !
    !
    !
    !     input parameters
    !
    !     nlat   the number of colatitudes on the full sphere including the
    !            poles. for example, nlat = 37 for a five degree grid.
    !            nlat determines the grid increment in colatitude as
    !            pi/(nlat-1).  if nlat is odd the equator is located at
    !            grid point i=(nlat + 1)/2. if nlat is even the equator is
    !            located half way between points i=nlat/2 and i=nlat/2+1.
    !            nlat must be at least 3. note: on the half sphere, the
    !            number of grid points in the colatitudinal direction is
    !            nlat/2 if nlat is even or (nlat + 1)/2 if nlat is odd.
    !
    !     nlon   the number of distinct londitude points.  nlon determines
    !            the grid increment in longitude as 2*pi/nlon. for example
    !            nlon = 72 for a five degree grid. nlon must be greater
    !            than 3. the axisymmetric case corresponds to nlon=1.
    !            the efficiency of the computation is improved when nlon
    !            is a product of small prime numbers.
    !
    !
    !     isym   this has the same value as the isym that was input to
    !            subroutine shaec to compute the arrays a and b.  isym
    !            determines whether (v, w) are computed on the full or half
    !            sphere as follows:
    !
    !      = 0
    !            vort is not symmetric about the equator. in this case
    !            the vector field (v, w) is computed on the entire sphere.
    !            i.e., in the arrays  v(i, j), w(i, j) for i=1, ..., nlat and
    !            j=1, ..., nlon.
    !
    !      = 1
    !
    !            vort is symmetric about the equator. in this case w is
    !            antiymmetric and v is symmetric about the equator. v
    !            and w are computed on the northern hemisphere only.  i.e.,
    !            if nlat is odd they are computed for i=1, ..., (nlat + 1)/2
    !            and j=1, ..., nlon.  if nlat is even they are computed for
    !            i=1, ..., nlat/2 and j=1, ..., nlon.
    !
    !       = 2
    !
    !            vort is antisymmetric about the equator. in this case w is
    !            symmetric and v is antisymmetric about the equator. w
    !            and v are computed on the northern hemisphere only.  i.e.,
    !            if nlat is odd they are computed for i=1, ..., (nlat + 1)/2
    !            and j=1, ..., nlon.  if nlat is even they are computed for
    !            i=1, ..., nlat/2 and j=1, ..., nlon.
    !
    !
    !     nt     in the program that calls ivrtec, nt is the number of vorticity
    !            and vector fields.  some computational efficiency is obtained
    !            for multiple fields.  the arrays a, b, v, and w can be three
    !            dimensional and pertrb can be one dimensional corresponding
    !            to an indexed multiple array vort.  in this case, multiple vector
    !            synthesis will be performed to compute each vector field.  the
    !            third index for a, b, v, w and first for pertrb is the synthesis
    !            index which assumes the values k=1, ..., nt.  for a single
    !            synthesis set nt=1. the description of the remaining parameters
    !            is simplified by assuming that nt=1 or that a, b, v, w are two
    !            dimensional and pertrb is a constant.
    !
    !     idvw   the first dimension of the arrays v, w as it appears in
    !            the program that calls ivrtec. if isym = 0 then idvw
    !            must be at least nlat.  if isym = 1 or 2 and nlat is
    !            even then idvw must be at least nlat/2. if isym = 1 or 2
    !            and nlat is odd then idvw must be at least (nlat + 1)/2.
    !
    !     jdvw   the second dimension of the arrays v, w as it appears in
    !            the program that calls ivrtec. jdvw must be at least nlon.
    !
    !     a, b    two or three dimensional arrays (see input parameter nt)
    !            that contain scalar spherical harmonic coefficients
    !            of the vorticity array vort as computed by subroutine shaec.
    !     ***    a, b must be computed by shaec prior to calling ivrtec.
    !
    !     mdab   the first dimension of the arrays a and b as it appears in
    !            the program that calls ivrtec (and shaec). mdab must be at
    !            least min(nlat, (nlon+2/2) if nlon is even or at least
    !            min(nlat, (nlon + 1)/2) if nlon is odd.
    !
    !     ndab   the second dimension of the arrays a and b as it appears in
    !            the program that calls ivrtec (and shaec). ndab must be at
    !            least nlat.
    !
    !
    !  wvhsec    an array which must be initialized by subroutine vhseci.
    !            once initialized
    !            wvhsec can be used repeatedly by ivrtec as long as nlon
    !            and nlat remain unchanged.  wvhsec must not be altered
    !            between calls of ivrtec.
    !
    !
    !  lvhsec    the dimension of the array wvhsec as it appears in the
    !            program that calls ivrtec. define
    !
    !               l1 = min(nlat, nlon/2) if nlon is even or
    !               l1 = min(nlat, (nlon + 1)/2) if nlon is odd
    !
    !            and
    !
    !               l2 = nlat/2        if nlat is even or
    !               l2 = (nlat + 1)/2    if nlat is odd
    !
    !            then lvhsec must be at least
    !
    !            4*nlat*l2+3*max(l1-2, 0)*(2*nlat-l1-1)+nlon+15
    !
    !     output parameters
    !
    !
    !     v, w   two or three dimensional arrays (see input parameter nt) that
    !           contain a divergence free vector field whose vorticity is
    !           vort - pertrb at the lattitude point theta(i)=pi/2-(i-1)*pi/(nlat-1)
    !           and longitude point lambda(j)=(j-1)*2*pi/nlon.  w is the east
    !           longitude component and v is the colatitudinal component.  the
    !           indices for v and w are defined at the input parameter isym.
    !           the divergence of (v, w) is the zero scalar field.
    !
    !   pertrb  a nt dimensional array (see input parameter nt and assume nt=1
    !           for the description that follows).  vort - pertrb is a scalar
    !           field which can be the vorticity of a vector field (v, w).
    !           pertrb is related to the scalar harmonic coefficients a, b
    !           of vort (computed by shaec) by the formula
    !
    !                pertrb = a(1, 1)/(2.*sqrt(2.))
    !
    !           an unperturbed vort can be the vorticity of a vector field
    !           only if a(1, 1) is zero.  if a(1, 1) is nonzero (flagged by
    !           pertrb nonzero) then subtracting pertrb from vort yields a
    !           scalar field for which a(1, 1) is zero.
    !
    !    ierror = 0  no errors
    !           = 1  error in the specification of nlat
    !           = 2  error in the specification of nlon
    !           = 3  error in the specification of isym
    !           = 4  error in the specification of nt
    !           = 5  error in the specification of idvw
    !           = 6  error in the specification of jdvw
    !           = 7  error in the specification of mdab
    !           = 8  error in the specification of ndab
    !           = 9  error in the specification of lvhsec
    !
    module subroutine ivrtec(nlat, nlon, isym, nt, v, w, idvw, jdvw, a, b, mdab, ndab, &
        wvhsec, pertrb, ierror)

        ! Dummy arguments
        integer(ip), intent(in)  :: nlat
        integer(ip), intent(in)  :: nlon
        integer(ip), intent(in)  :: isym
        integer(ip), intent(in)  :: nt
        real(wp),    intent(out) :: v(idvw, jdvw, nt)
        real(wp),    intent(out) :: w(idvw, jdvw, nt)
        integer(ip), intent(in)  :: idvw
        integer(ip), intent(in)  :: jdvw
        real(wp),    intent(in)  :: a(mdab, ndab, nt)
        real(wp),    intent(in)  :: b(mdab, ndab, nt)
        integer(ip), intent(in)  :: mdab
        integer(ip), intent(in)  :: ndab
        real(wp),    intent(out) :: wvhsec(:)
        real(wp),    intent(out) :: pertrb(nt)
        integer(ip), intent(out) :: ierror

        ! Local variables
        integer(ip) :: imid, labc, lzz1, mmax
        integer(ip) :: mn, lwork, required_wavetable_size

        associate (lvhsec => size(wvhsec))

            ! Check calling arguments
            ierror = 1
            if (nlat < 3) return
            ierror = 2
            if (nlon < 4) return
            ierror = 3
            if (isym < 0 .or. isym > 2) return
            ierror = 4
            if (nt < 0) return
            ierror = 5
            imid = (nlat + 1)/2
            if ((isym == 0 .and. idvw < nlat) .or. &
                (isym /= 0 .and. idvw < imid)) return
            ierror = 6
            if (jdvw < nlon) return
            ierror = 7
            mmax = min(nlat, (nlon + 1)/2)
            if (mdab < min(nlat, (nlon+2)/2)) return
            ierror = 8
            if (ndab < nlat) return
            ierror = 9
            lzz1 = 2*nlat*imid
            labc = 3*(max(mmax-2, 0)*(2*nlat-mmax-1))/2
            required_wavetable_size = 2*(lzz1+labc)+nlon+15
            if (lvhsec < required_wavetable_size) return
            ierror = 0
            !
            ! Verify unsaved workspace length
            !
            mn = mmax*nlat*nt

            select case (isym)
                case (0)
                    lwork = imid*(2*nt*nlon+max(6*nlat, nlon))+2*mn+nlat
                case default
                    lwork = nlat*(2*nt*nlon+max(6*imid, nlon))+2*mn+nlat
            end select

            block
                integer(ip) :: icr, ici, iis, iwk, liwk
                real(wp)    :: work(lwork)

                ! Set workspace pointer indices
                icr = 1
                ici = icr + mn
                iis = ici + mn
                iwk = iis + nlat
                liwk = lwork-2*mn-nlat

                call ivrtec_lower_utility_routine(nlat, nlon, isym, nt, v, w, idvw, &
                    jdvw, work(icr:), work(ici:), mmax, work(iis:), mdab, ndab, a, b, &
                    wvhsec, lvhsec, work(iwk:), liwk, pertrb, ierror)
            end block
        end associate

    end subroutine ivrtec

    subroutine ivrtec_lower_utility_routine(nlat, nlon, isym, nt, v, w, idvw, jdvw, cr, ci, mmax, &
        sqnn, mdab, ndab, a, b, wsav, lwsav, wk, lwk, pertrb, ierror)

        real(wp) :: a
        real(wp) :: b
        real(wp) :: bi(mmax, nlat, nt)
        real(wp) :: br(mmax, nlat, nt)
        real(wp) :: ci
        real(wp) :: cr
        
        integer(ip) :: idvw
        integer(ip) :: ierror
        integer(ip) :: isym
        integer(ip) :: ityp
        integer(ip) :: jdvw
        
        integer(ip) :: lwk
        integer(ip) :: lwsav
        
        integer(ip) :: mdab
        integer(ip) :: mmax
        
        integer(ip) :: ndab
        integer(ip) :: nlat
        integer(ip) :: nlon
        integer(ip) :: nt
        real(wp) :: pertrb
        real(wp) :: sqnn
        real(wp) :: v
        real(wp) :: w
        real(wp) :: wk
        real(wp) :: wsav
        dimension v(idvw, jdvw, nt), w(idvw, jdvw, nt), pertrb(nt)
        dimension cr(mmax, nlat, nt), ci(mmax, nlat, nt), sqnn(nlat)
        dimension a(mdab, ndab, nt), b(mdab, ndab, nt)
        dimension wsav(lwsav), wk(lwk)

        call perform_setup_for_inversion(isym, ityp, a, b, sqnn, pertrb, cr, ci)

        ! Vector synthesize cr, ci into divergence free vector field (v, w)
        call vhsec(nlat, nlon, ityp, nt, v, w, idvw, jdvw, br, bi, cr, ci, &
            mmax, nlat, wsav, ierror)

    end subroutine ivrtec_lower_utility_routine

end submodule invert_vorticity_regular_grid
