!
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!     *                                                               *
!     *                  copyright (c) 1998 by UCAR                   *
!     *                                                               *
!     *       University Corporation for Atmospheric Research         *
!     *                                                               *
!     *                      all rights reserved                      *
!     *                                                               *
!     *                      SPHEREPACK version 3.2                   *
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
!
!
!
! ... file slapes.f
!
!     this file includes documentation and code for
!     subroutine slapes          i
!
! ... files which must be loaded with slapec.f
!
!     type_SpherepackAux.f, type_RealPeriodicTransform.f, shaes.f, shses.f
!
!
!
!     subroutine slapes(nlat, nlon, isym, nt, slap, ids, jds, a, b, mdab, ndab, 
!    +                  wshses, lshses, work, lwork, ierror)
!
!
!     given the scalar spherical harmonic coefficients a and b, precomputed
!     by subroutine shaes for a scalar field sf, subroutine slapes computes
!     the laplacian of sf in the scalar array slap.  slap(i, j) is the
!     laplacian of sf at the colatitude
!
!         theta(i) = (i-1)*pi/(nlat-1)
!
!     and east longitude
!
!         lambda(j) = (j-1)*2*pi/nlon
!
!     on the sphere.  i.e.
!
!         slap(i, j) =
!
!                  2                2
!         [1/sint*d (sf(i, j)/dlambda + d(sint*d(sf(i, j))/dtheta)/dtheta]/sint
!
!
!     where sint = sin(theta(i)).  the scalar laplacian in slap has the
!     same symmetry or absence of symmetry about the equator as the scalar
!     field sf.  the input parameters isym, nt, mdab, ndab must have the
!     same values used by shaes to compute a and b for sf. the associated
!     legendre functions are stored rather than recomputed as they are
!     in subroutine slapec.

!
!     input parameters
!
!     nlat   the number of colatitudes on the full sphere including the
!            poles. for example, nlat = 37 for a five degree grid.
!            nlat determines the grid increment in colatitude as
!            pi/(nlat-1).  if nlat is odd the equator is located at
!            grid point i=(nlat+1)/2. if nlat is even the equator is
!            located half way between points i=nlat/2 and i=nlat/2+1.
!            nlat must be at least 3. note: on the half sphere, the
!            number of grid points in the colatitudinal direction is
!            nlat/2 if nlat is even or (nlat+1)/2 if nlat is odd.
!
!     nlon   the number of distinct longitude points.  nlon determines
!            the grid increment in longitude as 2*pi/nlon. for example
!            nlon = 72 for a five degree grid. nlon must be greater
!            than zero. the axisymmetric case corresponds to nlon=1.
!            the efficiency of the computation is improved when nlon
!            is a product of small prime numbers.
!
!     isym   this parameter should have the same value input to subroutine
!            shaes to compute the coefficients a and b for the scalar field
!            sf.  isym is set as follows:
!
!            = 0  no symmetries exist in sf about the equator. scalar
!                 synthesis is used to compute slap on the entire sphere.
!                 i.e., in the array slap(i, j) for i=1, ..., nlat and
!                 j=1, ..., nlon.
!
!           = 1  sf and slap are antisymmetric about the equator. the
!                synthesis used to compute slap is performed on the
!                northern hemisphere only.  if nlat is odd, slap(i, j) is
!                computed for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.  if
!                nlat is even, slap(i, j) is computed for i=1, ..., nlat/2
!                and j=1, ..., nlon.
!
!
!           = 2  sf and slap are symmetric about the equator. the
!                synthesis used to compute slap is performed on the
!                northern hemisphere only.  if nlat is odd, slap(i, j) is
!                computed for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.  if
!                nlat is even, slap(i, j) is computed for i=1, ..., nlat/2
!                and j=1, ..., nlon.
!
!
!     nt     the number of analyses.  in the program that calls slapes
!            the arrays slap, a, and b can be three dimensional in which
!            case multiple synthesis will be performed.  the third index
!            is the synthesis index which assumes the values k=1, ..., nt.
!            for a single analysis set nt=1. the description of the
!            remaining parameters is simplified by assuming that nt=1
!            or that all the arrays are two dimensional.
!
!   ids      the first dimension of the array slap as it appears in the
!            program that calls slapes.  if isym = 0 then ids must be at
!            least nlat.  if isym > 0 and nlat is even then ids must be
!            at least nlat/2. if isym > 0 and nlat is odd then ids must
!            be at least (nlat+1)/2.
!
!   jds      the second dimension of the array slap as it appears in the
!            program that calls slapes. jds must be at least nlon.
!
!
!   a, b      two or three dimensional arrays (see input parameter nt)
!            that contain scalar spherical harmonic coefficients
!            of the scalar field sf as computed by subroutine shaes.
!     ***    a, b must be computed by shaes prior to calling slapes.
!
!
!    mdab    the first dimension of the arrays a and b as it appears
!            in the program that calls slapes.  mdab must be at
!            least min(nlat, (nlon+2)/2) if nlon is even or at least
!            min(nlat, (nlon+1)/2) if nlon is odd.
!
!    ndab    the second dimension of the arrays a and b as it appears
!            in the program that calls slapes. ndbc must be at least
!            least nlat.
!
!            mdab, ndab should have the same values input to shaes to
!            compute the coefficients a and b.
!
!
!    wshses  an array which must be initialized by subroutine shsesi
!            before calling slapes.  once initialized, wshses
!            can be used repeatedly by slapes as long as nlat and nlon
!            remain unchanged.  wshses must not be altered between calls
!            of slapes.
!
!    lshses  the dimension of the array wshses as it appears in the
!            program that calls slapes.  let
!
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            and
!
!               l2 = nlat/2        if nlat is even or
!               l2 = (nlat+1)/2    if nlat is odd
!
!            then lshses must be greater than or equal to
!
!               (l1*l2*(nlat+nlat-l1+1))/2+nlon+15.
!
!
!     work   a work array that does not have to be saved.
!
!
!     lwork  the dimension of the array work as it appears in the
!            program that calls slapes. define
!
!               l2 = nlat/2                    if nlat is even or
!               l2 = (nlat+1)/2                if nlat is odd
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            if isym is zero then lwork must be at least
!
!               (nt+1)*nlat*nlon + nlat*(2*nt*l1+1)
!
!            if isym is nonzero lwork must be at least
!
!               (nt+1)*l2*nlon + nlat*(2*nt*l1+1)
!
!     **************************************************************
!
!     output parameters
!
!
!    slap    a two or three dimensional arrays (see input parameter nt) that
!            contain the scalar laplacian of the scalar field sf.  slap(i, j)
!            is the scalar laplacian at the colatitude
!
!                 theta(i) = (i-1)*pi/(nlat-1)
!
!            and longitude
!
!                 lambda(j) = (j-1)*2*pi/nlon
!
!            for i=1, ..., nlat and j=1, ..., nlon.
!
!
!  ierror    a parameter which flags errors in input parameters as follows:
!
!            = 0  no errors detected
!
!            = 1  error in the specification of nlat
!
!            = 2  error in the specification of nlon
!
!            = 3  error in the specification of ityp
!
!            = 4  error in the specification of nt
!
!            = 5  error in the specification of ids
!
!            = 6  error in the specification of jds
!
!            = 7  error in the specification of mdbc
!
!            = 8  error in the specification of ndbc
!
!            = 9  error in the specification of lshses
!
!            = 10 error in the specification of lwork
!
!
! **********************************************************************
!                                                                              
!     end of documentation for slapes
!
! **********************************************************************
!
submodule(scalar_laplacian_routines) scalar_laplacian_regular_grid_saved

contains

    module subroutine slapes(nlat, nlon, isym, nt, slap, ids, jds, a, b, mdab, ndab, &
        wshses, lshses, work, lwork, ierror)

        ! Dummy arguments
        integer(ip), intent(in)  :: nlat
        integer(ip), intent(in)  :: nlon
        integer(ip), intent(in)  :: isym
        integer(ip), intent(in)  :: nt
        real(wp),    intent(out) :: slap(ids, jds, nt)
        integer(ip), intent(in)  :: ids
        integer(ip), intent(in)  :: jds
        real(wp),    intent(in)  :: a(mdab, ndab, nt)
        real(wp),    intent(in)  :: b(mdab, ndab, nt)
        integer(ip), intent(in)  :: mdab
        integer(ip), intent(in)  :: ndab
        real(wp),    intent(in)  :: wshses(lshses)
        integer(ip), intent(in)  :: lshses
        real(wp),    intent(out) :: work(lwork)
        integer(ip), intent(in)  :: lwork
        integer(ip), intent(out) :: ierror

        ! Local variables
        integer(ip) :: ia
        integer(ip) :: ib
        integer(ip) :: ifn
        integer(ip) :: imid
        integer(ip) :: iwk
        integer(ip) :: l1
        integer(ip) :: l2
        integer(ip) :: lpimn
        integer(ip) :: ls
        integer(ip) :: lwk
        integer(ip) :: lwkmin
        integer(ip) :: mmax
        integer(ip) :: mn
        integer(ip) :: nln

        ! Check input arguments
        ierror = 1
        if (nlat < 3) return
        ierror = 2
        if (nlon < 4) return
        ierror = 3
        if (isym < 0 .or. isym > 2) return
        ierror = 4
        if (nt < 0) return
        ierror = 5
        imid = (nlat+1)/2
        if ((isym == 0 .and. ids<nlat) .or. &
            (isym>0 .and. ids<imid)) return
        ierror = 6
        if (jds < nlon) return
        ierror = 7
        mmax = min(nlat, nlon/2+1)
        if (mdab < mmax) return
        ierror = 8
        if (ndab < nlat) return
        ierror = 9
        imid = (nlat+1)/2
        lpimn = (imid*mmax*(nlat+nlat-mmax+1))/2
        if (lshses < lpimn+nlon+15) return
        ierror = 10
        !
        !     set and verify unsaved work space length
        !
        ls = nlat
        if (isym > 0) ls = imid
        nln = nt*ls*nlon
        mn = mmax*nlat*nt
        !     lwkmin = nln+ls*nlon+2*mn+nlat
        !     if (lwork .lt. lwkmin) return
        l2 = (nlat+1)/2
        l1 = min(nlat, nlon/2+1)
        if (isym == 0) then
            lwkmin = (nt+1)*nlat*nlon + nlat*(2*nt*l1+1)
        else
            lwkmin = (nt+1)*l2*nlon + nlat*(2*nt*l1+1)
        end if
        if (lwork < lwkmin) return
        ierror = 0
        !
        !     set work space pointers
        !
        ia = 1
        ib = ia+mn
        ifn = ib+mn
        iwk = ifn+nlat
        lwk = lwork-2*mn-nlat
        call slapes_lower_routine(nlat, nlon, isym, nt, slap, ids, jds, a, b, mdab, ndab, &
            work(ia), work(ib), mmax, work(ifn), wshses, lshses, work(iwk), lwk, &
            ierror)

    end subroutine slapes

    subroutine slapes_lower_routine(nlat, nlon, isym, nt, slap, ids, jds, a, b, mdab, ndab, &
        alap, blap, mmax, fnn, wsave, lsave, wk, lwk, ierror)

        real(wp) :: a
        real(wp) :: alap
        real(wp) :: b
        real(wp) :: blap
        
        real(wp) :: fnn
        integer(ip) :: ids
        integer(ip) :: ierror
        integer(ip) :: isym
        integer(ip) :: jds
        
        integer(ip) :: lsave
        integer(ip) :: lwk
        
        integer(ip) :: mdab
        integer(ip) :: mmax
        
        integer(ip) :: ndab
        integer(ip) :: nlat
        integer(ip) :: nlon
        integer(ip) :: nt
        real(wp) :: slap
        real(wp) :: wk
        real(wp) :: wsave
        dimension slap(ids, jds, nt), a(mdab, ndab, nt), b(mdab, ndab, nt)
        dimension alap(mmax, nlat, nt), blap(mmax, nlat, nt), fnn(nlat)

        call perform_setup_for_scalar_laplacian(a, b, alap, blap, fnn)

        ! Synthesize alap, blap into slap
        call shses(nlat, nlon, isym, nt, slap, ids, jds, alap, blap, &
            mmax, nlat, wsave, lsave, wk, lwk, ierror)

    end subroutine slapes_lower_routine

end submodule scalar_laplacian_regular_grid_saved