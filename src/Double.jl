"""
    DoubleFloat{T} <: MultipartFloat

A pair of magnitude-ordered, non-overlapping Floats of type `T`.

`Double16`, `Double32`, `Double64` are aliases for
`DoubleFloat{Float16}`, `DoubleFloat{Float32}`, and
`DoubleFloat{Float64}`, respectively.
"""
struct DoubleFloat{T} <: MultipartFloat

   hi::T
   lo::T

   # this form ensure hi, lo are canonically valued
   function DoubleFloat(hi::T, lo::T) where {T<:IEEEFloat}
       hi, lo = two_sum(hi, lo)
       return new{T}(hi, lo)
   end

   # this form does not alter hi, lo
   function DoubleFloat{T}(hi::T, lo::T) where {T<:IEEEFloat}
       return new{T}(hi, lo)
   end

end

DoubleFloat(x::T1, y::T2) where {T1<:Real, T2<:Real} = DoubleFloat(promote(x, y)...)
DoubleFloat(x::T, y::T) where {T<:Integer} = DoubleFloat{Float64}(BigFloat(x) + BigFloat(y))

function DoubleFloat(x::DoubleFloat{T}) where {T<:IEEEFloat}
    hi,lo = HILO(x)
    hi,lo = two_sum(hi, lo)
    return DoubleFloat{T}(hi, lo)
end

const Double64 = DoubleFloat{Float64}
const Double32 = DoubleFloat{Float32}
const Double16 = DoubleFloat{Float16}

const ComplexD64 = Complex{DoubleFloat{Float64}}
const ComplexD32 = Complex{DoubleFloat{Float32}}
const ComplexD16 = Complex{DoubleFloat{Float16}}

@inline HI(x::T) where {T<:IEEEFloat} = x
@inline LO(x::T) where {T<:IEEEFloat} = zero(x)
@inline HILO(x::T) where {T<:IEEEFloat} = x, zero(x)

@inline HI(x::T) where {F<:IEEEFloat, T<:DoubleFloat{F}} = x.hi
@inline LO(x::T) where {F<:IEEEFloat, T<:DoubleFloat{F}} = x.lo
@inline HILO(x::T) where {F<:IEEEFloat, T<:DoubleFloat{F}} = x.hi, x.lo

@inline HI(x::Tuple{T,T}) where {T<:IEEEFloat} = x[1]
@inline LO(x::Tuple{T,T}) where {T<:IEEEFloat} = x[2]
@inline HILO(x::Tuple{T,T}) where {T<:IEEEFloat} = x

@inline HI(x::Tuple{T,T}) where {F<:IEEEFloat, T<:DoubleFloat{F}} = x[1]
@inline LO(x::Tuple{T,T}) where {F<:IEEEFloat, T<:DoubleFloat{F}} = x[2]
@inline HILO(x::Tuple{T,T}) where {F<:IEEEFloat, T<:DoubleFloat{F}} = x

@inline HI(x::Tuple{T1,T2}) where {T1,T2} = x[1]
@inline LO(x::Tuple{T1,T2}) where {T1,T2} = x[2]
@inline HILO(x::Tuple{T1,T2}) where {T1,T2} = x


"""
    Double64(x::Tuple{Float64, Float64})

Convert a tuple `x` of `Float64`s to a `Double64`.
"""
@inline Double64(x::Tuple{Float64,Float64}) = DoubleFloat(x[1], x[2])
"""
    Double32(x::Tuple{Float32, Float32})

Convert a tuple `x` of `Float32`s to a `Double32`.
"""
@inline Double32(x::Tuple{Float32,Float32}) = DoubleFloat(x[1], x[2])
"""
    Double16(x::Tuple{Float16, Float16})

Convert a tuple `x` of `Float16`s to a `Double16`.
"""
@inline Double16(x::Tuple{Float16,Float16}) = DoubleFloat(x[1], x[2])
@inline Double64(x::Tuple{T,T}) where {T<:IEEEFloat} = DoubleFloat(Float64(x[1]), Float64(x[2]))
@inline Double32(x::Tuple{T,T}) where {T<:IEEEFloat} = DoubleFloat(Float32(x[1]), Float32(x[2]))
@inline Double16(x::Tuple{T,T}) where {T<:IEEEFloat} = DoubleFloat(Float16(x[1]), Float16(x[2]))
@inline DoubleFloat(x::Tuple{T,T}) where {T<:AbstractFloat} = DoubleFloat{T}(x[1], x[2])

"""
    Double64(::Real)

Convert `x` to an extended precision `Double64`.
"""
@inline function Double64(x::T) where {T<:Real}
    if isfinite(x)
        hi = Float64(x)
        lo = Float64(x - Float64(hi))
    else
        hi = Float64(x)
        lo = NaN
    end
    return Double64(hi, lo)
end
"""
    Double32(::Real}

Convert `x` to an extended precision `Double32`.
"""
@inline function Double32(x::T) where {T<:Real}
    if isfinite(x)
        hi = Float32(x)
        lo = Float32(x - Float32(hi))
    else
        hi = Float32(x)
        lo = NaN32
    end
    return Double32(hi, lo)
end

"""
    Double16(::Real)

Convert `x` to an extended precision `Double16`.
"""
@inline function Double16(x::T) where {T<:Real}
    if isfinite(x)
        hi = Float16(x)
        lo = Float16(x - Float16(hi))
    else
        hi = Float16(x)
        lo = NaN16
    end
    return Double16(hi, lo)
end

"""
    Double64(hi::T) where {T <: Integer}

Promote `hi` to a `Float64` then convert to `Double64`.
"""
@inline Double64(hi::T) where {T<:Integer} = Double64(Float64(hi))

"""
    Double32(hi::T) where {T <: Integer}

Promote `hi` to a `Float32` then convert to `Double32`.
"""
@inline Double32(hi::T) where {T<:Integer} = Double32(Float32(hi))

"""
    Double16(hi::T) where {T <: Integer}

Promote `hi` to a `Float16` then convert to `Double16`.
"""
@inline Double16(hi::T) where {T<:Integer} = Double16(Float16(hi))

for (F,D,U) in ((:Float64, :Double64, :(Union{Float32, Float16})),
                (:Float32, :Double32, :(Union{Float64, Float16})),
                (:Float16, :Double16, :(Union{Float64, Float32})))
  @eval begin
    @inline $D(hi::T, lo::T) where {T<:$U} = $D($F(hi), $F(lo))
    @inline $D(hi::T, lo::I) where {T<:$U, I<:Integer} = $D($F(hi), $F(lo))
    @inline $D(hi::I, lo::T) where {T<:$U, I<:Integer} = $D($F(hi), $F(lo))
    @inline $D(hi::I, lo::I) where {I<:Integer} = $D($F(hi), $F(lo))
  end
end


DoubleFloat{T}(x::DoubleFloat{T}, y::T) where {T<:IEEEFloat} = DoubleFloat(x, DoubleFloat(y))
DoubleFloat{T}(x::T, y::DoubleFloat{T}) where {T<:IEEEFloat} = DoubleFloat(DoubleFloat(x), y)


"""
    Double64(x::Double32)

Promote a `Double32` to a `Double64` by converting the `hi` and `lo` attributes
of `x` to `Double64`s and adding in extended precision.
"""
Double64(x::Double32) = isfinite(x) ? Double64(two_sum(Float64(HI(x)), Float64(LO(x)))) : Double64(Float64(x))
Double64(x::Double16) = isfinite(x) ? Double64(two_sum(Float64(HI(x)), Float64(LO(x)))) : Double64(Float64(x))
"""
    Double32(x::Double16)

Promote a `Double16` to a `Double32` by converting the `hi` and `lo` attributes
of `x` to `Double32`s and adding in extended precision.
"""
Double32(x::Double16) = isfinite(x) ? Double32(BigFloat(x)) : Double32(Float32(x))
Double32(x::Double64) = isfinite(x) ? Double32(BigFloat(x)) : Double32(Float32(x))
Double16(x::Double64) = isfinite(x) ? Double16(BigFloat(x)) : Double16(Float16(x))
Double16(x::Double32) = isfinite(x) ? Double16(BigFloat(x)) : Double16(Float16(x))

# cleanup to support other pkgs
DoubleFloat(x::Float64) = Double64(x, 0.0)
DoubleFloat(x::Float32) = Double32(x, 0.0f0)
DoubleFloat(x::Float16) = Double16(x, zero(Float16))

precision(::Type{DoubleFloat{T}}) where {T<:IEEEFloat} = 2*precision(T)

eltype(::Type{DoubleFloat{T}}) where {T<:AbstractFloat} = T
eltype(x::DoubleFloat{T}) where {T<:AbstractFloat} = T

# a type specific hash function helps the type to 'just work'
const hash_double_lo = (UInt === UInt64) ? 0x9bad5ebab034fe78 : 0x72da40cb
const hash_0_double_lo = hash(zero(UInt), hash_double_lo)

@inline hash(z::DoubleFloat{T}, h::UInt) where {T<:IEEEFloat} =
    hash(z.hi, h) ⊻ hash(z.lo)

@inline hash(z::DoubleFloat{T}, h::UInt) where {F<:IEEEFloat, T<:DoubleFloat{F}} =
    hash(z.hi) ⊻ hash(z.lo)

@inline hash(z::DoubleFloat{T}, h::UInt) where {F<:IEEEFloat, G<:DoubleFloat{F}, T<:DoubleFloat{G}} =
    hash(z.hi) ⊻ hash(z.lo)

Base.precision(::DoubleFloat{T}) where {T<:IEEEFloat} = 2 * precision(T)

#=
ComplexD64(rea::DoubleFloat{T}, ima::DoubleFloat{T}) where {T<:IEEEFloat} =
    Complex(Double64(rea), Double64(ima))
ComplexD32(rea::DoubleFloat{T}, ima::DoubleFloat{T}) where {T<:IEEEFloat} =
    Complex(Double32(rea), Double32(ima))
ComplexD16(rea::DoubleFloat{T}, ima::DoubleFloat{T}) where {T<:IEEEFloat} =
    Complex(Double16(rea), Double16(ima))

ComplexD64(c::C) where {C<:Complex} = ComplexD64(real(c), imag(c))
ComplexD32(c::C) where {C<:Complex} = ComplexD32(real(c), imag(c))
ComplexD16(c::C) where {C<:Complex} = ComplexD16(real(c), imag(c))

ComplexD64(r::Real, i::Real) = ComplexD64(Double64(r), Double64(i))
ComplexD32(r::Real, i::Real) = ComplexD32(Double32(r), Double32(i))
ComplexD16(r::Real, i::Real) = ComplexD16(Double16(r), Double16(i))

ComplexD64(r::R) where {R<:Real} = ComplexD64(Double64(r), zero(Double64))
ComplexD32(r::R) where {R<:Real} = ComplexD32(Double32(r), zero(Double32))
ComplexD16(r::R) where {R<:Real} = ComplexD16(Double16(r), zero(Double16))
=#
