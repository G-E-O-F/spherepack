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
! ... file shsec.f
!
!     this file contains code and documentation for subroutines
!     shsec and shseci
!
! ... files which must be loaded with shsec.f
!
!     sphcom.f, hrfft.f
!
!     subroutine shsec(nlat, nlon, isym, nt, g, idg, jdg, a, b, mdab, ndab, 
!    +                    wshsec, lshsec, work, lwork, ierror)
!
!     subroutine shsec performs the spherical harmonic synthesis
!     on the arrays a and b and stores the result in the array g.
!     the synthesis is performed on an equally spaced grid.  the
!     associated legendre functions are recomputed rather than stored
!     as they are in subroutine shses.  the synthesis is described
!     below at output parameter g.
!
!     required files from spherepack2
!
!     sphcom.f, hrfft.f
!
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
!     nlon   the number of distinct londitude points.  nlon determines
!            the grid increment in longitude as 2*pi/nlon. for example
!            nlon = 72 for a five degree grid. nlon must be greater
!            than or equal to 4. the efficiency of the computation is
!            improved when nlon is a product of small prime numbers.
!
!     isym   = 0  no symmetries exist about the equator. the synthesis
!                 is performed on the entire sphere.  i.e. on the
!                 array g(i, j) for i=1, ..., nlat and j=1, ..., nlon.
!                 (see description of g below)
!
!            = 1  g is antisymmetric about the equator. the synthesis
!                 is performed on the northern hemisphere only.  i.e.
!                 if nlat is odd the synthesis is performed on the
!                 array g(i, j) for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.
!                 if nlat is even the synthesis is performed on the
!                 array g(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
!
!
!            = 2  g is symmetric about the equator. the synthesis is
!                 performed on the northern hemisphere only.  i.e.
!                 if nlat is odd the synthesis is performed on the
!                 array g(i, j) for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.
!                 if nlat is even the synthesis is performed on the
!                 array g(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
!
!     nt     the number of syntheses.  in the program that calls shsec, 
!            the arrays g, a and b can be three dimensional in which
!            case multiple syntheses will be performed.  the third
!            index is the synthesis index which assumes the values
!            k=1, ..., nt.  for a single synthesis set nt=1. the
!            discription of the remaining parameters is simplified
!            by assuming that nt=1 or that the arrays g, a and b
!            have only two dimensions.
!
!     idg    the first dimension of the array g as it appears in the
!            program that calls shsec.  if isym equals zero then idg
!            must be at least nlat.  if isym is nonzero then idg
!            must be at least nlat/2 if nlat is even or at least
!            (nlat+1)/2 if nlat is odd.
!
!     jdg    the second dimension of the array g as it appears in the
!            program that calls shsec.  jdg must be at least nlon.
!
!     a, b    two or three dimensional arrays (see the input parameter
!            nt) that contain the coefficients in the spherical harmonic
!            expansion of g(i, j) given below at the definition of the
!            output parameter g.  a(m, n) and b(m, n) are defined for
!            indices m=1, ..., mmax and n=m, ..., nlat where mmax is the
!            maximum (plus one) longitudinal wave number given by
!            mmax = min(nlat, (nlon+2)/2) if nlon is even or
!            mmax = min(nlat, (nlon+1)/2) if nlon is odd.
!
!     mdab   the first dimension of the arrays a and b as it appears
!            in the program that calls shsec. mdab must be at least
!            min(nlat, (nlon+2)/2) if nlon is even or at least
!            min(nlat, (nlon+1)/2) if nlon is odd.
!
!     ndab   the second dimension of the arrays a and b as it appears
!            in the program that calls shsec. ndab must be at least nlat
!
!     wshsec an array which must be initialized by subroutine shseci.
!            once initialized, wshsec can be used repeatedly by shsec
!            as long as nlon and nlat remain unchanged.  wshsec must
!            not be altered between calls of shsec.
!
!     lshsec the dimension of the array wshsec as it appears in the
!            program that calls shsec. define
!
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            and
!
!               l2 = nlat/2        if nlat is even or
!               l2 = (nlat+1)/2    if nlat is odd
!
!            then lshsec must be at least
!
!            2*nlat*l2+3*((l1-2)*(nlat+nlat-l1-1))/2+nlon+15
!
!
!     work   a work array that does not have to be saved.
!
!     lwork  the dimension of the array work as it appears in the
!            program that calls shsec. define
!
!               l2 = nlat/2        if nlat is even or
!               l2 = (nlat+1)/2    if nlat is odd
!
!            if isym is zero then lwork must be at least
!
!                    nlat*(nt*nlon+max(3*l2, nlon))
!
!            if isym is not zero then lwork must be at least
!
!                    l2*(nt*nlon+max(3*nlat, nlon))
!
!     **************************************************************
!
!     output parameters
!
!     g      a two or three dimensional array (see input parameter
!            nt) that contains the spherical harmonic synthesis of
!            the arrays a and b at the colatitude point theta(i) =
!            (i-1)*pi/(nlat-1) and longitude point phi(j) =
!            (j-1)*2*pi/nlon. the index ranges are defined above at
!            at the input parameter isym.  for isym=0, g(i, j) is
!            given by the the equations listed below.  symmetric
!            versions are used when isym is greater than zero.
!
!     the normalized associated legendre functions are given by
!
!     pbar(m, n, theta) = sqrt((2*n+1)*factorial(n-m)/(2*factorial(n+m)))
!                       *sin(theta)**m/(2**n*factorial(n)) times the
!                       (n+m)th derivative of (x**2-1)**n with respect
!                       to x=cos(theta)
!
!     define the maximum (plus one) longitudinal wave number
!     as   mmax = min(nlat, (nlon+2)/2) if nlon is even or
!          mmax = min(nlat, (nlon+1)/2) if nlon is odd.
!
!     then g(i, j) = the sum from n=0 to n=nlat-1 of
!
!                   .5*pbar(0, n, theta(i))*a(1, n+1)
!
!              plus the sum from m=1 to m=mmax-1 of
!
!                   the sum from n=m to n=nlat-1 of
!
!              pbar(m, n, theta(i))*(a(m+1, n+1)*cos(m*phi(j))
!                                    -b(m+1, n+1)*sin(m*phi(j)))
!
!
!     ierror = 0  no errors
!            = 1  error in the specification of nlat
!            = 2  error in the specification of nlon
!            = 3  error in the specification of isym
!            = 4  error in the specification of nt
!            = 5  error in the specification of idg
!            = 6  error in the specification of jdg
!            = 7  error in the specification of mdab
!            = 8  error in the specification of ndab
!            = 9  error in the specification of lshsec
!            = 10 error in the specification of lwork
!
!
! ****************************************************************
!     subroutine shseci(nlat, nlon, wshsec, lshsec, dwork, ldwork, ierror)
!
!     subroutine shseci initializes the array wshsec which can then
!     be used repeatedly by subroutine shsec.
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
!     nlon   the number of distinct londitude points.  nlon determines
!            the grid increment in longitude as 2*pi/nlon. for example
!            nlon = 72 for a five degree grid. nlon must be greater
!            than or equal to 4. the efficiency of the computation is
!            improved when nlon is a product of small prime numbers.
!
!     lshsec the dimension of the array wshsec as it appears in the
!            program that calls shseci. the array wshsec is an output
!            parameter which is described below. define
!
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            and
!
!               l2 = nlat/2        if nlat is even or
!               l2 = (nlat+1)/2    if nlat is odd
!
!            then lshsec must be at least
!
!            2*nlat*l2+3*((l1-2)*(nlat+nlat-l1-1))/2+nlon+15
!
!     dwork  a real work array that does not have to be
!            saved.
!
!     ldwork the dimension of array dwork as it appears in the program
!            that calls shseci.  ldwork must be at least nlat+1.
!
!     output parameters
!
!     wshsec an array which is initialized for use by subroutine shsec.
!            once initialized, wshsec can be used repeatedly by shsec
!            as long as nlon and nlat remain unchanged.  wshsec must
!            not be altered between calls of shsec.
!
!     ierror = 0  no errors
!            = 1  error in the specification of nlat
!            = 2  error in the specification of nlon
!            = 3  error in the specification of lshsec
!            = 4  error in the specification of ldwork
!
!
! ****************************************************************
subroutine shsec(nlat, nlon, isym, nt, g, idg, jdg, a, b, mdab, ndab, &
                    wshsec, lshsec, work, lwork, ierror)
implicit none
real :: a
real :: b
real :: g
integer :: idg
integer :: ierror
integer :: imid
integer :: ist
integer :: isym
integer :: iw1
integer :: jdg
integer :: labc
integer :: ls
integer :: lshsec
integer :: lwork
integer :: lzz1
integer :: mdab
integer :: mmax
integer :: ndab
integer :: nlat
integer :: nln
integer :: nlon
integer :: nt
real :: work
real :: wshsec
dimension g(idg, jdg, 1), a(mdab, ndab, 1), b(mdab, ndab, 1), wshsec(1), &
          work(1)
ierror = 1
if (nlat < 3) return
ierror = 2
if (nlon < 4) return
ierror = 3
if (isym < 0 .or. isym > 2) return
ierror = 4
if (nt < 0) return
ierror = 5
if ((isym == 0 .and. idg < nlat) .or. &
   (isym /= 0 .and. idg < (nlat+1)/2)) return
ierror = 6
if (jdg < nlon) return
ierror = 7
mmax = min(nlat, nlon/2+1)
if (mdab < mmax) return
ierror = 8
if (ndab < nlat) return
ierror = 9
imid = (nlat+1)/2
lzz1 = 2*nlat*imid
labc = 3*((mmax-2)*(nlat+nlat-mmax-1))/2
if (lshsec < lzz1+labc+nlon+15) return
ierror = 10
ls = nlat
if (isym > 0) ls = imid
nln = nt*ls*nlon
if (lwork < nln+max(ls*nlon, 3*nlat*imid)) return
ierror = 0
ist = 0
if (isym == 0) ist = imid
iw1 = lzz1+labc+1
call shsec1(nlat, isym, nt, g, idg, jdg, a, b, mdab, ndab, imid, ls, nlon, &
     work, work(ist+1), work(nln+1), work(nln+1), wshsec, wshsec(iw1))
return
end subroutine shsec
subroutine shsec1(nlat, isym, nt, g, idgs, jdgs, a, b, mdab, ndab, imid, &
                idg, jdg, ge, go, work, pb, walin, whrfft)
implicit none
real :: a
real :: b
real :: g
real :: ge
real :: go
integer :: i
integer :: i3
integer :: idg
integer :: idgs
integer :: imid
integer :: imm1
integer :: isym
integer :: j
integer :: jdg
integer :: jdgs
integer :: k
integer :: ls
integer :: m
integer :: mdab
integer :: mdo
integer :: mmax
integer :: modl
integer :: mp1
integer :: mp2
integer :: ndab
integer :: ndo
integer :: nlat
integer :: nlon
integer :: nlp1
integer :: np1
integer :: nt
real :: pb
real :: walin
real :: whrfft
real :: work
!
!     whrfft must have at least nlon+15 locations
!     walin must have 3*l*imid + 3*((l-3)*l+2)/2 locations
!     zb must have 3*l*imid locations
!
dimension g(idgs, jdgs, 1), a(mdab, ndab, 1), b(mdab, ndab, 1), &
          ge(idg, jdg, 1), go(idg, jdg, 1), pb(imid, nlat, 3), walin(1), &
          whrfft(1), work(1)
ls = idg
nlon = jdg
mmax = min(nlat, nlon/2+1)
mdo = mmax
if (mdo+mdo-1 > nlon) mdo = mmax-1
nlp1 = nlat+1
modl = mod(nlat, 2)
imm1 = imid
if (modl /= 0) imm1 = imid-1
do 80 k=1, nt
do 80 j=1, nlon
do 80 i=1, ls
ge(i, j, k)=0.
80 continue
if (isym == 1) go to 125
call alin (2, nlat, nlon, 0, pb, i3, walin)
do 100 k=1, nt
do 100 np1=1, nlat, 2
do 100 i=1, imid
ge(i, 1, k)=ge(i, 1, k)+a(1, np1, k)*pb(i, np1, i3)
100 continue
ndo = nlat
if (mod(nlat, 2) == 0) ndo = nlat-1
do 110 mp1=2, mdo
m = mp1-1
call alin (2, nlat, nlon, m, pb, i3, walin)
do 110 np1=mp1, ndo, 2
do 110 k=1, nt
do 110 i=1, imid
ge(i, 2*mp1-2, k) = ge(i, 2*mp1-2, k)+a(mp1, np1, k)*pb(i, np1, i3)
ge(i, 2*mp1-1, k) = ge(i, 2*mp1-1, k)+b(mp1, np1, k)*pb(i, np1, i3)
110 continue
if (mdo == mmax .or. mmax > ndo) go to 122
call alin (2, nlat, nlon, mdo, pb, i3, walin)
do 120 np1=mmax, ndo, 2
do 120 k=1, nt
do 120 i=1, imid
ge(i, 2*mmax-2, k) = ge(i, 2*mmax-2, k)+a(mmax, np1, k)*pb(i, np1, i3)
120 continue
122 if (isym == 2) go to 155
125 call alin(1, nlat, nlon, 0, pb, i3, walin)
do 140 k=1, nt
do 140 np1=2, nlat, 2
do 140 i=1, imm1
go(i, 1, k)=go(i, 1, k)+a(1, np1, k)*pb(i, np1, i3)
140 continue
ndo = nlat
if (mod(nlat, 2) /= 0) ndo = nlat-1
do 150 mp1=2, mdo
mp2 = mp1+1
m = mp1-1
call alin(1, nlat, nlon, m, pb, i3, walin)
do 150 np1=mp2, ndo, 2
do 150 k=1, nt
do 150 i=1, imm1
go(i, 2*mp1-2, k) = go(i, 2*mp1-2, k)+a(mp1, np1, k)*pb(i, np1, i3)
go(i, 2*mp1-1, k) = go(i, 2*mp1-1, k)+b(mp1, np1, k)*pb(i, np1, i3)
150 continue
mp2 = mmax+1
if (mdo == mmax .or. mp2 > ndo) go to 155
call alin(1, nlat, nlon, mdo, pb, i3, walin)
do 152 np1=mp2, ndo, 2
do 152 k=1, nt
do 152 i=1, imm1
go(i, 2*mmax-2, k) = go(i, 2*mmax-2, k)+a(mmax, np1, k)*pb(i, np1, i3)
152 continue
155 do 160 k=1, nt
if (mod(nlon, 2) /= 0) go to 157
do 156 i=1, ls
ge(i, nlon, k) = 2.*ge(i, nlon, k)
156 continue
157 call hrfftb(ls, nlon, ge(1, 1, k), ls, whrfft, work)
160 continue
if (isym /= 0) go to 180
do 170 k=1, nt
do 170 j=1, nlon
do 175 i=1, imm1
g(i, j, k) = .5*(ge(i, j, k)+go(i, j, k))
g(nlp1-i, j, k) = .5*(ge(i, j, k)-go(i, j, k))
175 continue
if (modl == 0) go to 170
g(imid, j, k) = .5*ge(imid, j, k)
170 continue
return
180 do 185 k=1, nt
do 185 i=1, imid
do 185 j=1, nlon
g(i, j, k) = .5*ge(i, j, k)
185 continue
return
end subroutine shsec1
!     subroutine shseci(nlat, nlon, wshsec, lshsec, dwork, ldwork, ierror)
!
!     subroutine shseci initializes the array wshsec which can then
!     be used repeatedly by subroutine shsec.
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
!     nlon   the number of distinct londitude points.  nlon determines
!            the grid increment in longitude as 2*pi/nlon. for example
!            nlon = 72 for a five degree grid. nlon must be greater
!            than or equal to 4. the efficiency of the computation is
!            improved when nlon is a product of small prime numbers.
!
!     lshsec the dimension of the array wshsec as it appears in the
!            program that calls shseci. the array wshsec is an output
!            parameter which is described below. define
!
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            and
!
!               l2 = nlat/2        if nlat is even or
!               l2 = (nlat+1)/2    if nlat is odd
!
!            then lshsec must be at least
!
!            2*nlat*l2+3*((l1-2)*(nlat+nlat-l1-1))/2+nlon+15
!
!     dwork  a real work array that does not have to be
!            saved.
!
!     ldwork the dimension of array dwork as it appears in the program
!            that calls shseci.  ldwork must be at least nlat+1.
!
!     output parameters
!
!     wshsec an array which is initialized for use by subroutine shsec.
!            once initialized, wshsec can be used repeatedly by shsec
!            as long as nlon and nlat remain unchanged.  wshsec must
!            not be altered between calls of shsec.
!
!     ierror = 0  no errors
!            = 1  error in the specification of nlat
!            = 2  error in the specification of nlon
!            = 3  error in the specification of lshsec
!            = 4  error in the specification of ldwork
!
!
! ****************************************************************
subroutine shseci(nlat, nlon, wshsec, lshsec, dwork, ldwork, ierror)
implicit none
integer :: ierror
integer :: imid
integer :: iw1
integer :: labc
integer :: ldwork
integer :: lshsec
integer :: lzz1
integer :: mmax
integer :: nlat
integer :: nlon
real :: wshsec
dimension wshsec(*)
real dwork(ldwork)
ierror = 1
if (nlat < 3) return
ierror = 2
if (nlon < 4) return
ierror = 3
imid = (nlat+1)/2
mmax = min(nlat, nlon/2+1)
lzz1 = 2*nlat*imid
labc = 3*((mmax-2)*(nlat+nlat-mmax-1))/2
if (lshsec < lzz1+labc+nlon+15) return
ierror = 4
if (ldwork < nlat+1) return
ierror = 0
call alinit(nlat, nlon, wshsec, dwork)
iw1 = lzz1+labc+1
call hrffti(nlon, wshsec(iw1))
return
end subroutine shseci
