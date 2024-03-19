### A Pluto.jl notebook ###
# v0.19.39

using Markdown
using InteractiveUtils

# ╔═╡ 3c9eb960-d2b6-11ee-17eb-d9e0160a1c01
begin
	using CommonMark
	using JuMP, HiGHS, Ipopt	
	using PlutoUI
	using Plots, PlotThemes, LaTeXStrings
	using HypertextLiteral
	using Colors
	using LinearAlgebra, Random
	import Symbolics as S
	using NonlinearSolve
end

# ╔═╡ fbbae78d-ad90-4ca7-9e97-cce7796eec48
@htl("""
<style>
@import url("https://mmogib.github.io/math102/custom.css");

</style>
""")

# ╔═╡ 5c20b5fa-31bf-468b-85d2-1d48397ea552
TableOfContents(title="MATH474")

# ╔═╡ cc694ffa-ecda-492d-a8aa-e4c356182a03
md"""
# 4.5 The Dual Simplex Method
Consider the following example
```math
\begin{aligned}
& \operatorname{minimize} \quad 3 x_1+4 x_2+5 x_3 \\
& \text { subject to } \\
& x_1+2 x_2+3 x_3 \geqslant 5 \\
& 2 x_1+2 x_2+x_3 \geqslant 6 \\
& x_1 \geqslant 0, \quad x_2 \geqslant 0, \quad x_3 \geqslant 0 . \\
&
\end{aligned}
```
Write the __initial tableau__.
"""

# ╔═╡ 71cc7ea4-8a1a-46ff-8429-bc86860ab67d
md"""
__Remarks__:
- To work on the dual from the primal tableau is the __dual simplex method__. 
"""

# ╔═╡ e8d90800-4bdd-4512-ab9c-92ae96232f8c
md"""
## The dual Simplex Method
__Step 1__. Given a dual feasible basic solution ``\mathbf{x}_{\mathbf{B}}``, if ``\mathbf{x}_{\mathbf{B}} \geqslant \mathbf{0}`` the solution is optimal. If ``\mathbf{x}_{\mathbf{B}}`` is not nonnegative, select an index ``i`` such that the ``i`` th component of ``\mathbf{x}_{\mathbf{B}}, \mathbf{x}_{\mathbf{B} i}<0``.

__Step 2__. If all ``y_{i j} \geqslant 0, j=1,2, \ldots, n``, then the dual has no maximum (this follows since by (12) ``\overline{\boldsymbol{\lambda}}`` is feasible for all ``\varepsilon>0`` ). If ``y_{i j}<0`` for some ``j``, then let
```math
\varepsilon_0=\frac{z_k-c_k}{y_{i k}}=\min _j\left\{\frac{z_j-c_j}{y_{i j}}: y_{i j}<0\right\} .
```
__Step 3__. Form a new basis B by replacing $\mathbf{a}_i$ by $\mathbf{a}_k$. Using this basis determine the corresponding basic dual feasible solution $\mathbf{x}_{\mathbf{B}}$ and return to Step 1 .
"""

# ╔═╡ af6e2d6b-7edc-4650-b909-3e5991e22abb
begin
	A = [1 2 3;2 2 1]
	b= [5;6]
	c= [3;4;5]
	T0 = vcat(hcat(-A,I,-b),hcat(c',zeros(1,3)))
	zjs = -T0[end,1:3]
	ratios = findmin(zjs ./ T0[2,1:3])
	T0[2,:] = -(1/2)*T0[2,:]
	T0[1,:] = T0[2,:] + T0[1,:]
	T0[3,:] = -3T0[2,:] + T0[3,:]
	# zjs = -T0[end,[2,3,5]]
	# ratios = findmin(zjs ./ T0[1,[2,3,5]])
	T0[1,:] = -T0[1,:]
	T0[2,:] = -T0[1,:] + T0[2,:]
	T0[3,:] = -T0[1,:] + T0[3,:]
	T0
end

# ╔═╡ 872ac264-8ad4-4726-8e3f-7d3067b9cf62
md"""
```math
	x_1=1, \quad x_2=2, \quad, x_3 = 0
```
"""

# ╔═╡ 23db1b65-5377-460c-a4f4-fc79274455de
md"# 6.1 THE TRANSPORTATION PROBLEM"

# ╔═╡ 618a5356-526d-41f1-83b7-f01e6c377b7b
cm"""

<div class="img-container">

$(Resource("https://miro.medium.com/v2/resize:fit:4800/format:webp/1*Y02LI2sEAOpzL_o9w8yEKg.png"))

</div>
"""

# ╔═╡ 8f074aab-7f6a-4dc5-bf43-1a5650ec1c2e
md"""

- `m` origins that contain various amounts of a commodity that must be shipped to 
- `n` destinations to meet demand requirements. 
- origin $i$ contains an amount $a_i$, and destination $j$ has a requirement of amount $b_j$. It is assumed that the system is balanced in the sense that total supply equals total demand. That is,
```math
\sum_{i=1}^m a_i=\sum_{j=1}^n b_j .
```
- The numbers $a_i$ and $b_j, i=1,2, \ldots, m ; j=1,2, \ldots, n$, are assumed to be nonnegative, and in many applications they are in fact nonnegative integers. 
- $\operatorname{cost} c_{i j}$ associated with the shipping of the commodity from origin $i$ to destination $j$. 

__The problem is to find the shipping pattern between origins and destinations that satisfies all the requirements and minimizes the total shipping cost.__

In mathematical terms the above problem can be expressed as finding a set of $x_{i j}^{\prime}$ 's, $i=1,2, \ldots, m ; j=1,2, \ldots, n$, to
```math
\begin{aligned}
& \operatorname{minimize} \sum_{i=1}^m \sum_{j=1}^n c_{i j} x_{i j} \\
& \text { subject to } \\
&\sum_{j=1}^n x_{i j}=a_i \text { for } i=1,2, \ldots, m \\
& \sum_{i=1}^m x_{i j}=b_j \text { for } j=1,2, \ldots, n \\
& x_{i j} \geqslant 0 \text { for } \text { all } i \text { and } j .
\end{aligned}
```
"""

# ╔═╡ ed9ef14b-df56-4b5e-a176-29876cbd3055
md"""
```math
\begin{aligned} x_{11}+x_{12}+\cdots+x_{1 n} &\cdots && =a_1 \\ 
\cdots & \quad x_{21}+x_{22}+\cdots+x_{2 n}&\cdots& =a_2 \\ & \vdots \\
 &&x_{m 1}+x_{m 2}+\cdots+x_{m n} & =a_m\end{aligned}
```

---

```math
\begin{aligned} 
x_{11}&+&x_{21} &+& x_{m 1} && & =b_1 \\ 
&x_{12}+&&x_{22} & & & &=b_2 \\ & & & \vdots \\ 
&&x_{1 n} & +&x_{2n} & +&x_{mn} & =b_n\end{aligned}
```
"""

# ╔═╡ a60a1aa9-0b27-4c28-8386-a15bdaa2fe28
cm"""
<div class="img-container">

$(Resource("https://cdn.mathpix.com/snip/images/CaHwD__M6hypQWqQ0dV57JhkXyk8fjc0KsH4jQ2WQKU.original.fullsize.png", :width=>300))

</div>
"""

# ╔═╡ 9f402990-6c34-4b16-8968-d55f6a523d73
let
	a = [30, 80, 10, 60]
	b = [10, 50, 20, 80, 20]
	C = [3 4 6 8 9;
	     2 2 4 5 5;
	     2 2 2 3 2;
	     3 3 2 4 2]
	m,n = size(C)
	model= Model(HiGHS.Optimizer)
	@variable(model,x[1:m,1:n]>=0)
	@constraint(model,supply[i in 1:m],sum(x[i,j] for j in 1:n)==a[i])
	@constraint(model,demand[j in 1:n],sum(x[i,j] for i in 1:m)==b[j])
	# @objective(model,Min,sum(C[i,j]*x[i,j] for i in 1:m for j in 1:n))
	@objective(model,Min, C[:] ⋅ x[:] )
	optimize!(model)
	value.(x)
end

# ╔═╡ 8b997cc9-6f72-45bd-ac50-64377f75b94a
# let
# 	model = Model(HiGHS.Optimizer)
# 	set_silent(model)
# 	@variable(model,x[i in 1:m,j in 1:n]>=0)
# 	@constraint(model, supply[i in 1:m],sum(x[i,j] for j in 1:n)==a[i])
# 	@constraint(model, demand[j in 1:n],sum(x[i,j] for i in 1:m)==b[j])
# 	@objective(model,Min, sum(C[i,j]*x[i,j] for i in 1:m for j in 1:n))
# 	optimize!(model)
# 	value.(x), objective_value(model)
# end

# ╔═╡ 642b4eff-8601-4ab3-9c81-13c600eb8d83
md"""
##  Feasibility and Redundancy
- A __feasible solution__ can be found by allocating shipments from origins to destinations in proportion to supply and demand requirements. 
Specifically, let $S$ be equal to the total supply (which is also equal to the total demand). Then let 
```math
x_{i j}=a_i b_j / S \quad \text{ for } i=1,2, \ldots, m ; j=1,2, \ldots, n.
```

"""

# ╔═╡ 1c24e128-7998-487d-a702-d4fa07ffd824
let
	a = [30, 80, 10, 60]
	b = [10, 50, 20, 80, 20];
	# sum(b)/length(a)
	S = sum(a)
	x = hcat([a[i]*b/S for i in 1:4]...)
	sum(x,dims=1)
end

# ╔═╡ 3ed35935-3fa1-44f5-89b9-0bab98129abe
md"""
# 6.2 FINDING A BASIC FEASIBLE SOLUTION
## The Northwest Corner Rule
__Example 1__
"""

# ╔═╡ a797bc8e-d269-46d5-9792-dff51fc6a91d
md"# Exam 1: Solution"

# ╔═╡ 7e900647-e813-4048-b41d-554edb5e9fd0
cm"""
## Q1
minimize:
```math
Z = -8x_1 + 9x_2 - 12x_3 - 4x_4 - 11x_5
```

Subject to the constraints:
```math
\begin{array}{lr}
\min & -8x_1 + 9x_2 - 12x_3 - 4x_4 - 11x_5 \\
\text{subject to} \\
& \begin{array}{llllllllllll}
-x_1& +& 3x_2& +& 6x_3& +& 2x_4& +& 3x_5 &\leq& 1 \\
x_1& +& 7x_2& -& 3x_3& +& 2x_4& +& x_5 &\leq& 2 \\
2x_1& +& 4x_2& -& 6x_3& +& 2x_4& +& 3x_5 &\leq& 4 \\
\end{array}\\
& x_1,x_2,x_3,x_4,x_5\geq 0
\end{array}

```
"""

# ╔═╡ 079522cf-7f45-46f3-b7d4-9457ac152712
begin
	f(x) = -8x[1] + 9x[2] - 12x[3] - 4x[4] - 11x[5]
	f1(x) = -x[1] + 3x[2] + 6x[3] + 2x[4] + 3x[5]
	f2(x) = x[1] + 7x[2] - 3x[3] + 2x[4] + x[5]
	f3(x) =  2x[1] + 4x[2] - 6x[3] + 2x[4] + 3x[5]
	g(x) =  -x[1] - 2x[2] - 4x[3]
	x = (5,0,1,0,0)
	y = (12,20,0)
	f(x),g(y)
end

# ╔═╡ caf4ec4a-2ed2-45c3-933a-ebf3565423c6
md"## Q2"

# ╔═╡ 25024b3d-3efa-468c-af58-2f71c9343f4c
let
# Q2
A = [1 2//3 0 0 4//3 0 4;
     0 -7//3 3 1 -2//3 0 2;
     0 -2//3 -2 0 2//3 1 2;
     0 8//3 -11 0 4//3 0 -8]	
	Binv = (1//3) * [1 1 -1;
              1 -2 2;
              -1 2 1]
	# B = inv(Binv)
	# D = B*A[1:3,[2,3,5]]
	# b = B*A[1:3,end]
	# cb=[-1 -3 1]
	# cd = [8//3 -11 4//3]+ cb*Binv*D
	# cd = [8//3 -11 4//3]+ cb*A[1:3,[2,3,5]]
	# Ao = hcat(B[:,1],D[:,[1,2]],B[:,2],D[:,3],B[:,3])
	# c = vcat(cb[1],cd[1:2],cb[2],cd[3],cb[3])
	# solver = optimizer_with_attributes(
	# 	HiGHS.Optimizer,
	# 	MOI.Silent()=>true,
	# )
	# model=Model(solver)
	# @variable(model,x[1:6]>=0)
	# @constraint(model,Ao*x==b)
	# @objective(model,Min,dot(c,x))
	# optimize!(model)
	# value.(x)
	# # cd,b
	# B
end

# ╔═╡ 06dd3a31-241a-42e2-bd79-2fe3fc42431b
md"""
# 7.1 FIRST-ORDER NECESSARY CONDITIONS
In this chapter we consider optimization problems of the form
```math
\begin{array}{ll}
\text { minimize } & f(\mathbf{x}) \\
\text { subject to } & \mathbf{x} \in \Omega,
\end{array}
```
where 
- ``f`` is a real-valued function and 
- ``\Omega``, the feasible set, is a subset of $E^n$.
- when $\Omega=E^n$, unconstrained case.
"""

# ╔═╡ 30c25578-a317-469f-9eba-9f60016d1112
md"##  Feasible Directions"

# ╔═╡ c5167913-d173-4c0e-902c-caf72d952862
let
	model = Model(Ipopt.Optimizer)
	set_silent(model)
	@variable(model,x[1:2])
	@objective(model,Min,x[1]^2-x[1]x[2]+x[2]^2-3x[2])
	optimize!(model)
	value.(x)
end

# ╔═╡ 485ef383-6611-4ef4-a8c9-157a10f4a72b
let
	# model = Model(Ipopt.Optimizer)
	# set_silent(model)
	# @variable(model,x[1:2]>=0)
	# @objective(model,Min,x[1]^2-x[1]+x[2]+x[1]x[2])
	# optimize!(model)
	# value.(x)
end

# ╔═╡ fc2d6469-4819-4057-a916-7ac6fcf66ea5
md"""
# 7.2 EXAMPLES OF UNCONSTRAINED PROBLEMS
## Example 1 (Production). 
A common problem in economic theory is the determination of the best way to combine various inputs in order to produce a certain commodity. There is a known production function $f\left(x_1, x_2, \ldots, x_n\right)$ that gives the amount of the commodity produced as a function of the amounts $x_i$ of the inputs, $i=1,2, \ldots, n$. The unit price of the produced commodity is $q$, and the unit prices of the inputs are $p_1, p_2, \ldots, p_n$. The producer wishing to maximize profit must solve the problem
```math
\operatorname{maximize} \quad q f\left(x_1, x_2, \ldots, x_n\right)-p_1 x_1-p_2 x_2 \ldots-p_n x_n .
```
"""

# ╔═╡ 0671bb10-76e3-4f7e-a3b6-96caf5a070b0
md"""
## Example 3 (Selection problem). 
It is often necessary to select an assortment of factors to meet a given set of requirements. An example is the problem faced by an electric utility when selecting its power-generating facilities. The level of power that the company must supply varies by time of the day, by day of the week, and by season. Its power-generating requirements are summarized by a curve, $h(x)$, as shown in Fig. 7.2(a), which shows the total hours in a year that a power level of at least $x$ is required for each $x$. For convenience the curve is normalized so that the upper limit is unity.

The power company may meet these requirements by installing generating equipment, such as (1) nuclear or (2) coal-fired, or by purchasing power from a central energy grid. Associated with type $i(i=1,2)$ of generating equipment is a yearly unit capital cost $b_i$ and a unit operating cost $c_i$. The unit price of power purchased from the grid is $c_3$.

Nuclear plants have a high capital cost and low operating cost, so they are used to supply a base load. Coal-fired plants are used for the intermediate level, and power is purchased directly only for peak demand periods. The requirements are satisfied as shown in Fig. 7.2(b), where $x_1$ and $x_2$ denote the capacities of the nuclear and coal-fired plants, respectively. (For example, the nuclear power plant can be visualized as consisting of $x_1 / \Delta$ small generators of capacity $\Delta$, where $\Delta$ is small. The first such generator is on for about $h(\Delta)$ hours, supplying $\Delta h(\Delta)$ units of energy; the next supplies $\Delta h(2 \Delta)$ units, and so forth. The total energy supplied by the nuclear plant is thus the area shown.)
The total cost is
```math
\begin{array}{rl}
f\left(x_1, x_2\right)=b_1 x_1+b_2 x_2+c_1 \int_0^{x_1} & h(x) d x \\
& +c_2 \int_{x_1}^{x_1+x_2} h(x) d x+c_3 \int_{x_1+x_2}^1 h(x) d x,
\end{array}
```
hours required
(a)
hours required
(b)
"""

# ╔═╡ 1c1bc517-024a-4ca9-8348-0d5efa6c7ed8
md"# 7.3 SECOND-ORDER CONDITIONS"

# ╔═╡ f5540b83-0a1f-4eb6-aa37-8b55ba12c8e9
let
	# Global min is (0.5, 0)
	
	# S.@variables x[1:2] d[1:2]
	# f(x)=x[1]^2-x[1]+x[2]+x[1]*x[2]
	# f(x)
	# J =S.gradient(f(x),x)
	# # J(y) =S.substitute(S.gradient(f(x),x),Dict(x[1]=>1,x[2]=>3))
	# Jd(y) = S.substitute([J...],Dict(x=>y))
	# Jd(d)
	# dot(Jd([0.5,0]),d)
end

# ╔═╡ 193bce30-2e11-47b6-8d34-79ea396c3034
cm"""
__Remak__

-  For notational simplicity we often denote ``\nabla^2 f(\mathbf{x})``, the ``n \times n`` matrix of the second partial derivatives of ``f``, the __Hessian__ of ``f``, by the alternative notation ``\mathbf{F}(\mathbf{x})``.
"""

# ╔═╡ 6615890a-a5c7-495d-8a62-86a26409784b
let
	# solutions: (0,0) and (6,9)
	# S.@variables x[1:2] d[1:2]
	# f(x)=x[1]^3-x[1]^2*x[2]+2x[2]^2
	# f(x)
	# J =S.gradient(f(x),x)
	# Jd(y) = S.substitute([J...],Dict(x=>y))
	# Jd(x)
	# dot(Jd([0.5,0]),d)
end

# ╔═╡ 3d331b72-2956-4128-9640-7724a939daac
md"## Sufficient Conditions for a Relative Minimum"

# ╔═╡ 4a785bd1-3425-464a-af96-68671db569c3
md"#  7.4 CONVEX AND CONCAVE FUNCTIONS"

# ╔═╡ 8f74a55d-cbdb-4f05-95a1-96d9be27d2e2
md"## Combinations of Convex Functions"

# ╔═╡ a9254790-cf6d-43bf-b5d3-4651b39e8c71
md"## Properties of Differentiable Convex Functions"

# ╔═╡ 5deaf9ac-444d-4555-8e1d-7db3634e9ca0
let
	# x=-5:0.1:5
	
	# plot(x,x,(x,y)->2*(x)^2-4*x*y-8*x+3*y)
	x, y = -10:0.1:10, -10:0.1:10
	# z = 2*x.^2-4*x .* y .- 8*x .+ 3*y
	surface(x,y,(x,y)->2*x^2-4*x * y - 8*x + 3*y)
end

# ╔═╡ 7a0e19df-c652-4c12-a3c1-c4d91807622b
md"# 7.5 MINIMIZATION AND MAXIMIZATION OF CONVEX FUNCTIONS"

# ╔═╡ 7b420807-ba90-4445-8ee5-57dd682027f0
md"# 7.6 ZERO-ORDER CONDITIONS"

# ╔═╡ b78ac359-0208-4311-96af-9e026eb8fe86
cm"""
We consier
```math
\begin{array}{cc}\operatorname{minimize} & f(\mathbf{x}) \\ \text { subject to } & \mathbf{x} \in \Omega\end{array}\tag{7.6.1}
```
- The problem is constrained by the set ``\Omega``. This
constraint influences the first- and second-order necessary and sufficient conditions
 through the relation between feasible directions and derivatives of the function ``f``.
-  There is a way to treat this constraint __without reference to derivatives__.
 The resulting conditions are then of __zero order__
	- The simplest assumptions for the necessary conditions are
 that ``\Omega`` is a convex set and that ``f`` is a convex function on all of ``E^n``.
"""

# ╔═╡ 1eca3903-f777-400d-8e86-d85ca40f2354
cm"""
Let ``x^*\in \Omega`` and consider the tabular region ``\mathbb{B}`` defined as
```math
\mathbb{B} \subset E^{n+1}=\{(r,x)\; :\; r\leq f(x^*), x\in\Omega \}
```

See the figure below
<div class="img-container">

$(Resource("https://www.dropbox.com/scl/fi/oahs3svj5l1tr6opc28fx/sec7_5_1.png?rlkey=dudq18vb38l3nwuj4p0soozd8&raw=1",:width=>400))
</div>
"""

# ╔═╡ ad4d0e42-07bf-43b0-8ef8-f87208d88faf
cm"""
According to the separating hyperplane theorem (Appendix B), there is a hyperplane separating these two sets. This hyperplane can be represented by a nonzero vector of the form ``(s, \boldsymbol{\lambda}) \in E^{n+1}`` with ``s`` a scalar and ``\boldsymbol{\lambda} \in E^n``, and a separation constant ``c``. The separation conditions are
```math
\begin{align}
s r+\boldsymbol{\lambda}^T \mathbf{x} \geq c & \text { for all } \mathbf{x} \in E^n \text { and } r \geq f(\mathbf{x}) \tag{7.6.2}\\
s r+\boldsymbol{\lambda}^T \mathbf{x} \leq c & \text { for all } \mathbf{x} \in \Omega \text { and } r \leq f^* \tag{7.6.3}.
\end{align}
```

It follows that ``s \neq 0``; for otherwise ``\boldsymbol{\lambda} \neq \mathbf{0}`` and then (15) would be violated for some ``\mathbf{x} \in E^n``. It also follows that ``s \geqslant 0`` since otherwise (16) would be violated by very negative values of ``r``. Hence, together we find ``s>0`` and by appropriate scaling we may take ``s=1``.
"""

# ╔═╡ 72cf0a7d-36fa-4533-9257-ed4f56a12374
md"# 8.6 THE METHOD OF STEEPEST DESCENT"

# ╔═╡ c9a1b17b-8cb2-4025-96b1-0064e090c5f8
cm"""
The __method of steepest descent__ is defined by the iterative algorithm
```math
\displaystyle \mathbf{x}_{k+1}=\displaystyle \mathbf{x}_k-\alpha_k \mathbf{g}_k,
```
where ``\alpha_k`` is a nonnegative scalar minimizing ``f\left(\mathbf{x}_k-\alpha \mathbf{g}_k\right)`` and ``g_k=\nabla f(x_k)``. 
"""

# ╔═╡ 9884c49e-4b4e-4f01-894e-0453710ac997
cm"""
## Global Convergence
If sequence ``x_k`` is bounded, it will have limit points and each of these is a solution.

"""

# ╔═╡ 3f66b21e-e20c-4c36-99d8-9ae934b8df0f
md"## The Quadratic Case"

# ╔═╡ a10353ef-7267-41a9-9620-d6829b0b0c6c
cm"""
Consider
```math
f(\mathbf{x})=\frac{1}{2} \mathbf{x}^T \mathbf{Q} \mathbf{x}-\mathbf{x}^T \mathbf{b},
```
where 
- ``\mathbf{Q}`` is a positive definite symmetric ``n \times n`` matrix. 
- Since ``\mathbf{Q}`` is positive definite, all of its eigenvalues are positive. We assume that these eigenvalues are ordered: ``0<`` ``a=\lambda_1 \leqslant \lambda_2 \ldots \leqslant \lambda_n=A``. With ``\mathbf{Q}`` positive definite, it follows (from Proposition 5, Section 7.4 ) that ``f`` is strictly convex.
- The method of steepest descent takes the explicit form
```math
\mathbf{x}_{k+1}=\mathbf{x}_k-\left(\frac{\mathbf{g}_k^T \mathbf{g}_k}{\mathbf{g}_k^T \mathbf{Q} \mathbf{g}_k}\right) \mathbf{g}_k,\quad \text{where}\quad  \mathbf{g}_k=\mathbf{Q} \mathbf{x}_k-\mathbf{b}.
``` 

"""

# ╔═╡ 8df3e745-dde4-4f85-ba43-ae46ec5e669a
let
	pltit(p,x,i=1)=scatter(p,[x[1]],[x[2]],label=:none,annotation=[(x[1],x[2]+0.5,text(L"x_%$i,%$(round(f(x),digits=2))",8))])
	n=2
	Random.seed!(123)
	U = rand(-2:3,n,n)
	Q = U*diagm(rand(1:6,n))*inv(U)
	b = rand(-5:5,n)
	f(x::Vector{<:Number}) =0.5*(Q*x⋅x) - x⋅b
	x = -10:0.1:10
	y = copy(x)
	p = contour(x,y,(x,y)->f([x,y]))
	xstar = Q\b
	p = scatter(p,[xstar[1]],[xstar[2]],label=L"(%$(xstar[1]),%$(xstar[2])),%$(f(xstar))")
	x1=[5,5]
	p = pltit(p,x1)
	function xnew(x)
		gk = Q*x-b
		αk = dot(gk,gk)/dot(Q*gk,gk)
		x-αk*gk
	end
	x2=xnew(x1)
	p = pltit(p,x2,2)
	# f.([xstar,x2])
	x3=xnew(x2)
	p = pltit(p,x3,3)
	# f.([xstar,x2,x3])
	p = plot(p,xlims=(-2,-1))
	x4=xnew(x3)
	p = pltit(p,x4,4)
	# f.([xstar,x2,x3,x4])
	# x5=xnew(x4)
	# p = pltit(p,x5,5)
	# norm(Q*x5-b)
	# ev,evv = eigen(Q);
	# λmin,λmax = minimum(ev),maximum(ev)
	# cn =λmax/λmin
	# fac =((λmax-λmin)/(λmin+λmax))^2
	# f.([xstar,x2,x3,x4])
	# Ek(x)=0.5*dot(Q*(x-xstar),x-xstar)
	# Ek(x3)/Ek(x2), fac
	
end

# ╔═╡ 0a350a34-3c76-4de1-ad48-c05b0d7cefee
begin
	function poolcode()
		cm"""
<div class="img-container">

$(Resource("https://www.dropbox.com/s/cat9ots4ausfzyc/qrcode_itempool.com_kfupm.png?raw=1",:width=>300))

</div>"""
	end
	function bbl(t)
		beginBlock(t,"")
	end
	function bbl(t,s)
		beginBlock(t,s)
	end
	ebl()=endBlock()
	function bth(s)
		beginTheorem(s)
	end
	eth()=endTheorem()
	ex(n::Int;s::String="")=ex("Example $n",s)
	ex(t,s)=example(t,s)
	function beginBlock(title,subtitle)
		"""<div style="box-sizing: border-box;">
		<div style="display: flex;flex-direction: column;border: 6px solid rgba(200,200,200,0.5);box-sizing: border-box;">
		<div style="display: flex;">
		<div style="background-color: #FF9733;
		    border-left: 10px solid #df7300;
		    padding: 5px 10px;
		    color: #fff!important;
		    clear: left;
		    margin-left: 0;font-size: 112%;
		    line-height: 1.3;
		    font-weight: 600;">$title</div>  <div style="olor: #000!important;
		    margin: 0 0 20px 25px;
		    float: none;
		    clear: none;
		    padding: 5px 0 0 0;
		    margin: 0 0 0 20px;
		    background-color: transparent;
		    border: 0;
		    overflow: hidden;
		    min-width: 100px;font-weight: 600;
		    line-height: 1.5;">$subtitle</div>
		</div>
		<p style="padding:5px;">
	"""
	end
	function beginTheorem(subtitle)
		beginBlock("Theorem",subtitle)
	end
	function endBlock()
		"""</p></div></div>"""
	end
	function endTheorem()
		 endBlock()
	end
	function example(lable,desc)
		"""<div style="display:flex;">
	<div style="
	font-size: 112%;
	    line-height: 1.3;
	    font-weight: 600;
	    color: #f9ce4e;
	    float: left;
	    background-color: #5c5c5c;
	    border-left: 10px solid #474546;
	    padding: 5px 10px;
	    margin: 0 12px 20px 0;
	    border-radius: 0;
	">$lable:</div>
	<div style="flex-grow:3;
	line-height: 1.3;
	    font-weight: 600;
	    float: left;
	    padding: 5px 10px;
	    margin: 0 12px 20px 0;
	    border-radius: 0;
	">$desc</div>
	</div>"""
	end
	@htl("")
end


# ╔═╡ a14cf195-bc83-4003-aac4-a6ab8b59fbdb
cm"""
$(ex(1))
 an example, which will be solved completely in a later section, a specific transportation problem with four origins and five destinations is defined by
```math
\begin{array}{l}
\begin{array}{l}
\mathbf{a}=(30,80,10,60)\\
\\
\mathbf{b}=(10,50,20,80,20)
\end{array} & \mathbf{C}=\left[\begin{array}{lllll}
3 & 4 & 6 & 8 & 9 \\
2 & 2 & 4 & 5 & 5 \\
2 & 2 & 2 & 3 & 2 \\
3 & 3 & 2 & 4 & 2
\end{array}
\right]
\end{array}
```

Note that the balance requirement is satisfied, since the sum of the supply and the demand are both 180 .
"""

# ╔═╡ 60596838-ca36-44d1-8945-c0d5beb51352
cm"""
$(bth("")) 
A transportation problem always has a solution, but there is exactly one redundant equality constraint. When any one of the equality constraints is dropped, the remaining system of ``n+m-1`` equality constraints is linearly independent.
$(eth())
"""

# ╔═╡ c340930f-0e86-4db6-92ed-b950679ce212
cm"""
$(bbl("Definition.","Local Minimum Point"))
A point ``\mathbf{x}^* \in \Omega`` is said to be a __relative minimum__ point or a __local minimum__ point of ``f`` over ``\Omega`` if there is an ``\varepsilon>0`` such that ``f(\mathbf{x}) \geqslant f\left(\mathbf{x}^*\right)`` for all ``\mathbf{x} \in \Omega`` within a distance ``\varepsilon`` of ``\mathbf{x}^*`` (that is, ``\mathbf{x} \in \Omega`` and ``\left|\mathbf{x}-\mathbf{x}^*\right|<\varepsilon`` ). If ``f(\mathbf{x})>f\left(\mathbf{x}^*\right)`` for all ``\mathbf{x} \in \Omega, \mathbf{x} \neq \mathbf{x}^*``, within a distance ``\varepsilon`` of ``\mathbf{x}^*``, then ``\mathbf{x}^*`` is said to be a __strict relative minimum__ point of ``f`` over ``\Omega``.
$(ebl())

$(bbl("Definition.","Global Minimum Point"))
A point ``\mathbf{x}^* \in \Omega`` is said to be a __global minimum__ point of ``f`` over ``\Omega`` if ``f(\mathbf{x}) \geqslant f\left(\mathbf{x}^*\right)`` for all ``\mathbf{x} \in \Omega``. If ``f(\mathbf{x})>f\left(\mathbf{x}^*\right)`` for all ``\mathbf{x} \in \Omega, \mathbf{x} \neq \mathbf{x}^*``, then ``\mathbf{x}^*`` is said to be a __strict global minimum__ point of ``f`` over ``\Omega``.
$(ebl())
"""

# ╔═╡ 83279d1a-899b-4e61-9e3d-b8545e1aca28
cm"""
$(bbl("Definition.","Feasible Direction"))
Given ``\mathbf{x} \in \Omega``, we say that a vector ``\mathbf{d}`` is a feasible direction at ``\mathbf{x}`` if there is an ``\bar{\alpha}>0`` such that ``\mathbf{x}+\alpha \mathbf{d} \in \Omega`` for all ``\alpha, 0 \leqslant \alpha \leqslant \bar{\alpha}``. 
$(ebl())
"""

# ╔═╡ 1f5b4a38-cb54-436c-8313-eafcbad27d85
cm"""
$(bbl("Proposition 1"," (First-order necessary conditions)"))
Let ``\Omega`` be a subset of ``E^n`` and let ``f \in C^1`` be a function on ``\Omega``. If ``\mathbf{x}^*`` is a relative minimum point of ``f`` over ``\Omega``, then for any ``\mathbf{d} \in E^n`` that is a feasible direction at ``\mathbf{x}^*``, we have ``\boldsymbol{\nabla} f\left(\mathbf{x}^*\right) \mathbf{d} \geqslant 0``.
$(ebl())
"""

# ╔═╡ 1ad6d5b8-656c-416e-883c-0ccbee9767c4
cm"""
$(bbl("Corollary","(Unconstrained case)"))
 Let ``\Omega`` be a subset of ``E^n``, and let ``f \in C^1`` be a function' on ``\Omega``. If ``\mathbf{x}^*`` is a relative minimum point of ``f`` over ``\Omega`` and if ``\mathbf{x}^*`` is an interior point of ``\Omega``, then ``\boldsymbol{\nabla} f\left(\mathbf{x}^*\right)=\mathbf{0}``.
$(ebl())
"""

# ╔═╡ 65d970e8-8868-4176-9715-7ebfa3ec7f40
cm"""
$(ex(1)) Consider the problem
```math
\operatorname{minimize} f\left(x_1, x_2\right)=x_1^2-x_1 x_2+x_2^2-3 x_2 \text {. }
```
"""

# ╔═╡ e212d318-fb3f-4844-b29d-e22965577b76
cm"""
$(ex(2))Consider the problem
```math
\begin{array}{ll}
\operatorname{minimize} & f\left(x_1, x_2\right)=x_1^2-x_1+x_2+x_1 x_2 \\
\text { subject to } & x_1 \geqslant 0, \quad x_2 \geqslant 0 .
\end{array}
```
"""

# ╔═╡ 86f41264-49c6-4dd6-a3bd-8a61cdb4c22a
cm"""
$(bbl("Proposition 1","(Second-order necessary conditions)"))

Let ``\Omega`` be a subset of ``E^n`` and let ``f \in C^2`` be a function on ``\Omega``. If ``\mathbf{x}^*`` is a relative minimum point of ``f`` over ``\Omega``, then for any ``\mathbf{d} \in E^n`` that is a feasible direction at ``\mathbf{x}^*`` we have

- ``\boldsymbol{\nabla} f\left(\mathbf{x}^*\right) \mathbf{d} \geqslant 0``
- if ``\boldsymbol{\nabla} f\left(\mathbf{x}^*\right) \mathbf{d}=0``, then ``\mathbf{d}^T \boldsymbol{\nabla}^2 f\left(\mathbf{x}^*\right) \mathbf{d} \geqslant 0``.
$(ebl())
"""

# ╔═╡ fc96902a-eecb-4d9d-a698-bafdeab6e6ba
cm"""
$(ex(1))Consider the Problem 2 in Section 7.1; that is
```math
\begin{array}{ll}
\operatorname{minimize} & f\left(x_1, x_2\right)=x_1^2-x_1+x_2+x_1 x_2 \\
\text { subject to } & x_1 \geqslant 0, \quad x_2 \geqslant 0 .
\end{array}
```
"""

# ╔═╡ b770509e-02f4-471d-a6ea-3027cfe7ecb3
cm"""
$(bbl("Proposition 2","(Second-order necessary conditions-unconstrained case)"))
Let ``\mathbf{x}^*`` be an interior point of the set ``\Omega``, and suppose ``\mathbf{x}^*`` is a relative minimum point over ``\Omega`` of the function ``f \in C^2``. Then

1. ``\boldsymbol{\nabla} f\left(\mathbf{x}^*\right)=\mathbf{0}``
2. for all ``\mathbf{d}, \mathbf{d}^T \nabla^2 f\left(\mathbf{x}^*\right) \mathbf{d} \geqslant 0``.
$(ebl())
"""

# ╔═╡ c23bbd07-06a4-4d31-b657-f1127ac56a43
cm"""
$(ex(2)) Consider the problem
```math
\begin{array}{ll}
\operatorname{minimize} & f\left(x_1, x_2\right)=x_1^3-x_1^2 x_2+2 x_2^2 \\
\text { subject to } & x_1 \geqslant 0, \quad x_2 \geqslant 0 .
\end{array}
```
"""

# ╔═╡ 2b4fdfd0-805e-4df2-bb6c-d6515f08bf1d
cm"""
$(bbl("Proposition 3","(Second-order sufficient conditions-unconstrained case)"))
Let ``f \in C^2`` be a function defined on a region in which the point ``\mathbf{x}^*`` is an interior point. Suppose in addition that
1. ``\boldsymbol{\nabla} f\left(\mathbf{x}^*\right)=\mathbf{0}``
2. ``\mathbf{F}\left(\mathbf{x}^*\right)`` is positive definite.

Then ``\mathbf{x}^*`` is a strict relative minimum point of ``f``.
$(ebl())
"""

# ╔═╡ 5b197020-0e19-4a55-911c-97effb9c2f1a
cm"""
$(bbl("Definition.",""))
A function ``f`` defined on a convex set ``\Omega`` is said to be __convex__ if, for every ``\mathbf{x}_1, \mathbf{x}_2 \in \Omega`` and every ``\alpha, 0 \leqslant \alpha \leqslant 1``, there holds
```math
f\left(\alpha \mathbf{x}_1+(1-\alpha) \mathbf{x}_2\right) \leqslant \alpha f\left(\mathbf{x}_1\right)+(1-\alpha) f\left(\mathbf{x}_2\right) .
```

If, for every ``\alpha, 0<\alpha<1``, and ``\mathbf{x}_1 \neq \mathbf{x}_2``, there holds
```math
f\left(\alpha \mathbf{x}_1+(1-\alpha) \mathbf{x}_2\right)<\alpha f\left(\mathbf{x}_1\right)+(1-\alpha) f\left(\mathbf{x}_2\right),
```
then ``f`` is said to be __strictly convex__.

$(bbl("Definition.",""))
A function ``g`` defined on a convex set ``\Omega`` is said to be concave if the function ``f=-g`` is convex. The function ``g`` is strictly concave if ``-g`` is strictly convex.
"""

# ╔═╡ d5a02d24-26f5-492d-a708-873c9a7b52ad
cm"""
$(bbl("Proposition 1","")) Let ``f_1`` and ``f_2`` be convex functions on the convex set ``\Omega``. Then the function ``f_1+f_2`` is convex on ``\Omega``.

$(bbl("Proposition 2","")) Let ``f`` be a convex function over the convex set ``\Omega``. Then the function af is convex for any ``a \geqslant 0``.

$(bbl("Proposition 3","")) Let ``f`` be a convex function on a convex set ``\Omega``. The set ``\Gamma_c=\{\mathbf{x}: \mathbf{x} \in \Omega, f(\mathbf{x}) \leqslant c\}`` is convex for every real number ``c``.
"""

# ╔═╡ 7cac9247-5b78-4a9c-ad7c-88fa4c9445f8
cm"""
$(bbl("Proposition 4","")) Let ``f \in C^1``. Then ``f`` is convex over a convex set ``\Omega`` if and only if
```math
f(\mathbf{y}) \geqslant f(\mathbf{x})+\nabla f(\mathbf{x})(\mathbf{y}-\mathbf{x})
```
for all ``\mathbf{x}, \mathbf{y} \in \boldsymbol{\Omega}``.

$(bbl("Proposition 5","")) Let ``f \in C^2``. Then ``f`` is convex over a convex set ``\Omega`` containing an interior point if and only if the Hessian matrix ``\mathbf{F}`` of ``f`` is positive semidefinite throughout ``\Omega``.
"""

# ╔═╡ 46b16316-cbdc-4165-84ad-37b896067c4e
cm"""
$(bbl("Definition")) A mapping ``B: \mathbb{R}^n \rightarrow \mathbb{R}^p`` is AFFINE if there exist a linear mapping ``A: \mathbb{R}^n \rightarrow \mathbb{R}^p`` and an element ``b \in \mathbb{R}^p`` such that ``B(x)=A(x)+b`` for all ``x \in \mathbb{R}^n``.
$(ebl())

Every linear mapping is affine. Moreover, ``B: \mathbb{R}^n \rightarrow \mathbb{R}^p`` is affine if and only if ``B(\lambda x+(1-\lambda) y)=\lambda B(x)+(1-\lambda) B(y)`` for all ``x, y \in \mathbb{R}^n`` and ``\lambda \in \mathbb{R}``.

$(bbl("Proposition")) Let ``B: \mathbb{R}^n \rightarrow \mathbb{R}^p`` be an affine mapping and let ``f: \mathbb{R}^p \rightarrow \mathbb{R}`` be a convex function. Then the composition ``f \circ B`` is convex.
$(ebl())

$(bbl("Corollary")) Let ``f: \mathbb{R}^n \rightarrow \mathbb{R}`` be a convex function. For any ``\bar{x}, d \in \mathbb{R}^n``, the function ``\varphi: \mathbb{R} \rightarrow \mathbb{R}`` defined by ``\varphi(t):=f(\bar{x}+t d)`` is convex as well. Conversely, if for every ``\bar{x}, d \in \mathbb{R}^n`` the function ``\varphi`` defined above is convex, then ``f`` is also convex.
$(ebl())
"""

# ╔═╡ 698ba26d-219c-4f9d-8cff-c959e28f94b7
cm"""
$(bbl("Theorem"))  Suppose that ``f: \mathbb{R} \rightarrow \mathbb{R}`` is differentiable on its domain, which is an open interval ``I``. Then ``f`` is convex if and only if the derivative ``f^{\prime}`` is nondecreasing on ``I``.
$(ebl())

$(bbl("Corollary")) Let ``f: \mathbb{R} \rightarrow \overline{\mathbb{R}}`` be twice differentiable on its domain, which is an open interval I. Then ``f`` is convex if and only if ``f^{\prime \prime}(x) \geq 0`` for all ``x \in I``.
$(ebl())
"""

# ╔═╡ 5f72f759-e632-44b6-b051-bd831f2ffae7
cm"""
$(bbl("Examples"))
1. Show that the following functions are convex on the given domains:
	- ``f_1(x)=(x-1)^3`` on ``(1,\infty)``.
	- ``f_2(x)=x\ln x`` on ``(0,\infty)``.
2. Is ``g(x)=\max(f_1(x),f_2(x))`` convex?
3. Is ``h(x)=\min(f_1(x),f_2(x))`` convex?
4. Which of the following functions is convex, concave, or neither? Why?
	- ``f\left(x_1, x_2\right)=2 x_1^2-4 x_1 x_2-8 x_1+3 x_2``
	- ``f\left(x_1, x_2\right)=x_1 e^{-\left(x_1+3 x_2\right)}``
$(ebl())
"""

# ╔═╡ fd68a71f-3055-43f1-8015-e99f5cdead9e
cm"""
$(bbl("Theorem 1")) Let ``f`` be a convex function defined on the convex set ``\Omega``. Then the set ``\Gamma`` where ``f`` achieves its minimum is convex, and any relative minimum of ``f`` is a global minimum.
$(ebl())
"""

# ╔═╡ 52f09e05-f5f2-44ac-855f-fd03cb0e21fe
cm"""
$(bbl("Theorem 2")) Let ``f \in C^1`` be convex on the convex set ``\Omega``. If there is a point ``\mathbf{x}^* \in \Omega`` such that, for all ``\mathbf{y} \in \Omega, \nabla f\left(\mathbf{x}^*\right)\left(\mathbf{y}-\mathbf{x}^*\right) \geqslant 0``, then ``\mathbf{x}^*`` is a global minimum point of ``f`` over ``\Omega``.
$(ebl())
"""

# ╔═╡ 68a8f065-bd02-45e2-a0e4-bebce750f733
cm"""
$(bbl("Theorem 3")) Let ``f`` be a convex function defined on the bounded, closed convex set ``\Omega``. If ``f`` has a maximum over ``\Omega`` it is achieved at an extreme point of ``\Omega``.
$(ebl())
"""

# ╔═╡ 24a4a121-92ab-4766-9b0c-ff0bd3dcfa51
cm"""
$(bbl("Definition")) 
The set 
```math
\Gamma \subset E^{n+1}=\left\{(r, \mathbf{x}): r \geqslant f(\mathbf{x}), \mathbf{x} \in E^n\right\}
```
is called the __epigraph of ``f``__. 
$(ebl())

- It is easy to verify that the set ``\Gamma`` is convex if ``f`` is a convex function.
"""

# ╔═╡ 111cfd65-7dec-4c4b-aa7d-f7c53a47f3a6
cm"""
$(bbl("Proposition 1", "Zero-order necessary conditions"))
If ``\mathbf{x}^*`` solves ``(7.6.1)`` under the stated convexity conditions, then there is a nonzero vector ``\boldsymbol{\lambda} \in E^n`` such that ``\mathbf{x}^*`` is a solution to the two problems:
```math
\begin{array}{ll}
\text { minimize } & f(\mathbf{x})+\boldsymbol{\lambda}^T \mathbf{x} \\
\text { subject to } & \mathbf{x} \in E^n
\end{array}\tag{7.6.4}
```
and
```math
\begin{array}{ll}
\text { maximize } & \boldsymbol{\lambda}^T \mathbf{x} \\
\text { subject to } & \mathbf{x} \in \Omega .\tag{7.6.5}
\end{array}
```
$(ebl())
"""

# ╔═╡ e2986fb8-ac1c-4591-aa7d-57919815b243
cm"""
$(bbl("Remark"))
__Sufficient Conditions.__ The conditions of Proposition 1 are sufficient for ``\mathbf{x}^*`` to be a minimum even without the convexity assumptions.
$(ebl())
"""

# ╔═╡ 4af8b8c2-ef21-4143-ad6c-f056c90f8854
cm"""
$(bbl("Proposition 2","(Zero-order sufficiency conditions)"))
If there is a ``\boldsymbol{\lambda}`` such that ``\mathbf{x}^* \in \Omega`` solves the problems ``(7.6.4)`` and ``(7.6.5)``, then ``\mathbf{x}^*`` solves ``(7.6.1)``.
$(ebl())
"""


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
CommonMark = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
Ipopt = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
NonlinearSolve = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
PlotThemes = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"

[compat]
Colors = "~0.12.10"
CommonMark = "~0.8.12"
HiGHS = "~1.8.1"
HypertextLiteral = "~0.9.5"
Ipopt = "~1.6.1"
JuMP = "~1.19.0"
LaTeXStrings = "~1.3.1"
NonlinearSolve = "~3.8.0"
PlotThemes = "~3.1.0"
Plots = "~1.40.1"
PlutoUI = "~0.7.55"
Symbolics = "~5.22.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.2"
manifest_format = "2.0"
project_hash = "005f433cd95dc1a94a6574893ec9125a98e34acd"

[[deps.ADTypes]]
git-tree-sha1 = "41c37aa88889c171f1300ceac1313c06e891d245"
uuid = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
version = "0.2.6"

[[deps.ASL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6252039f98492252f9e47c312c8ffda0e3b9e78d"
uuid = "ae81ac8f-d209-56e5-92de-9978fef736f9"
version = "0.1.3+0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "c278dfab760520b8bb7e9511b968bf4ba38b7acc"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.3"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "e2a9873379849ce2ac9f9fa34b0e37bde5d5fe0a"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.0.2"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra", "Requires", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "881e43f1aa014a6f75c8fc0847860e00a1500846"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.8.0"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceReverseDiffExt = "ReverseDiff"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.ArrayLayouts]]
deps = ["FillArrays", "LinearAlgebra"]
git-tree-sha1 = "e46675dbc095ddfdf2b5fba247d5a25f34e1f8a2"
uuid = "4c555306-a7a7-4459-81d9-ec55ddd5c99a"
version = "1.6.1"
weakdeps = ["SparseArrays"]

    [deps.ArrayLayouts.extensions]
    ArrayLayoutsSparseArraysExt = "SparseArrays"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "f1f03a9fa24271160ed7e73051fba3c1a759b53f"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.4.0"

[[deps.Bijections]]
git-tree-sha1 = "c9b163bd832e023571e86d0b90d9de92a9879088"
uuid = "e2ed5e7c-b2de-5872-ae92-c73ca462fb04"
version = "0.1.6"

[[deps.BitFlags]]
git-tree-sha1 = "2dc09997850d68179b69dafb58ae806167a32b1b"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.8"

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "0c5f81f47bbbcf4aea7b2959135713459170798b"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.5"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9e2a6b69137e6969bab0152632dcb3bc108c8bdd"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+1"

[[deps.CPUSummary]]
deps = ["CpuId", "IfElse", "PrecompileTools", "Static"]
git-tree-sha1 = "601f7e7b3d36f18790e2caf83a882d88e9b71ff1"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.2.4"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "575cd02e080939a33b6df6c5853d14924c08e35b"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.23.0"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CloseOpenIntervals]]
deps = ["Static", "StaticArrayInterface"]
git-tree-sha1 = "70232f82ffaab9dc52585e0dd043b5e0c6b714f1"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.12"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "9b1ca1aa6ce3f71b3d1840c538a8210a043625eb"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.8.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "59939d8a997469ee05c4b4944560a820f9ba0d73"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.4"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "67c1f244b991cad9b0aa4b7540fb758c2488b129"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.24.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.CommonMark]]
deps = ["Crayons", "JSON", "PrecompileTools", "URIs"]
git-tree-sha1 = "532c4185d3c9037c0237546d817858b23cf9e071"
uuid = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
version = "0.8.12"

[[deps.CommonSolve]]
git-tree-sha1 = "0eee5eb66b1cf62cd6ad1b460238e60e4b09400c"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.4"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "75bd5b6fc5089df449b5d35fa501c846c9b6549b"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.12.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.0+0"

[[deps.CompositeTypes]]
git-tree-sha1 = "02d2316b7ffceff992f3096ae48c7829a8aa0638"
uuid = "b152e2b5-7a66-4b01-a709-34e65c35f657"
version = "0.1.3"

[[deps.ConcreteStructs]]
git-tree-sha1 = "f749037478283d372048690eb3b5f92a79432b34"
uuid = "2569d6c7-a4a2-43d3-a901-331e8e4be471"
version = "0.2.3"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "9c4708e3ed2b799e6124b5673a712dda0b596a9b"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.3.1"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "c53fc348ca4d40d7b371e71fd52251839080cbc9"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.4"
weakdeps = ["IntervalSets", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.CpuId]]
deps = ["Markdown"]
git-tree-sha1 = "fcbb72b032692610bfbdb15018ac16a36cf2e406"
uuid = "adafc99b-e345-5852-983c-f28acb93d879"
version = "0.3.1"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "ac67408d9ddf207de5cfa9a97e114352430f01ed"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.16"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DiffEqBase]]
deps = ["ArrayInterface", "DataStructures", "DocStringExtensions", "EnumX", "EnzymeCore", "FastBroadcast", "ForwardDiff", "FunctionWrappers", "FunctionWrappersWrappers", "LinearAlgebra", "Logging", "Markdown", "MuladdMacro", "Parameters", "PreallocationTools", "PrecompileTools", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "Setfield", "SparseArrays", "Static", "StaticArraysCore", "Statistics", "Tricks", "TruncatedStacktraces"]
git-tree-sha1 = "b19b2bb1ecd1271334e4b25d605e50f75e68fcae"
uuid = "2b5f629d-d688-5b77-993f-72d75c75574e"
version = "6.148.0"

    [deps.DiffEqBase.extensions]
    DiffEqBaseChainRulesCoreExt = "ChainRulesCore"
    DiffEqBaseDistributionsExt = "Distributions"
    DiffEqBaseEnzymeExt = ["ChainRulesCore", "Enzyme"]
    DiffEqBaseGeneralizedGeneratedExt = "GeneralizedGenerated"
    DiffEqBaseMPIExt = "MPI"
    DiffEqBaseMeasurementsExt = "Measurements"
    DiffEqBaseMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    DiffEqBaseReverseDiffExt = "ReverseDiff"
    DiffEqBaseTrackerExt = "Tracker"
    DiffEqBaseUnitfulExt = "Unitful"

    [deps.DiffEqBase.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    GeneralizedGenerated = "6b9d7cbe-bcb9-11e9-073f-15a7a543e2eb"
    MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "7c302d7a5fec5214eb8a5a4c466dcf7a51fcf169"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.107"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.DomainSets]]
deps = ["CompositeTypes", "IntervalSets", "LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "9f9e38f361c9a72eeb28e515d3e0328f2d50076e"
uuid = "5b8099bc-c8ec-5219-889f-1d9e522a28bf"
version = "0.7.9"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.DynamicPolynomials]]
deps = ["Future", "LinearAlgebra", "MultivariatePolynomials", "MutableArithmetics", "Pkg", "Reexport", "Test"]
git-tree-sha1 = "0bb0a6f812213ecc8fbbcf472f4a993036858971"
uuid = "7c1d4256-1411-5781-91ec-d7bc3513ac07"
version = "0.5.5"

[[deps.EnumX]]
git-tree-sha1 = "bdb1942cd4c45e3c678fd11569d5cccd80976237"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.4"

[[deps.EnzymeCore]]
git-tree-sha1 = "59c44d8fbc651c0395d8a6eda64b05ce316f58b4"
uuid = "f151be2c-9106-41f4-ab19-57ee4f262869"
version = "0.6.5"
weakdeps = ["Adapt"]

    [deps.EnzymeCore.extensions]
    AdaptExt = "Adapt"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "dcb08a0d93ec0b1cdc4af184b26b591e9695423a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.10"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "4558ab818dcceaab612d1bb8c19cee87eda2b83c"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.5.0+0"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FastBroadcast]]
deps = ["ArrayInterface", "LinearAlgebra", "Polyester", "Static", "StaticArrayInterface", "StrideArraysCore"]
git-tree-sha1 = "a6e756a880fc419c8b41592010aebe6a5ce09136"
uuid = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
version = "0.2.8"

[[deps.FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[deps.FastLapackInterface]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "0a59c7d1002f3131de53dc4568a47d15a44daef7"
uuid = "29a986be-02c6-4525-aec4-84b980013641"
version = "2.0.2"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random"]
git-tree-sha1 = "5b93957f6dcd33fc343044af3d48c215be2562f1"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.9.3"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "73d1214fec245096717847c62d389a5d2ac86504"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.22.0"

    [deps.FiniteDiff.extensions]
    FiniteDiffBandedMatricesExt = "BandedMatrices"
    FiniteDiffBlockBandedMatricesExt = "BlockBandedMatrices"
    FiniteDiffStaticArraysExt = "StaticArrays"

    [deps.FiniteDiff.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "cf0fe81336da9fb90944683b8c41984b08793dad"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.36"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d8db6a5a2fe1381c1ea4ef2cab7c69c2de7f9ea0"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.1+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.FunctionWrappers]]
git-tree-sha1 = "d62485945ce5ae9c0c48f124a84998d755bae00e"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.3"

[[deps.FunctionWrappersWrappers]]
deps = ["FunctionWrappers"]
git-tree-sha1 = "b104d487b34566608f8b4e1c39fb0b10aa279ff8"
uuid = "77dc65aa-8811-40c2-897b-53d922fa7daf"
version = "0.1.3"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "ff38ba61beff76b8f4acad8ab0c97ef73bb670cb"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.9+0"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "ec632f177c0d990e64d955ccc1b8c04c485a0950"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.6"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "UUIDs", "p7zip_jll"]
git-tree-sha1 = "3458564589be207fa6a77dbbf8b97674c9836aab"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.73.2"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "77f81da2964cc9fa7c0127f941e8bce37f7f1d70"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.73.2+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "e94c92c7bf4819685eb80186d51c43e71d4afa17"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.76.5+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "899050ace26649433ef1af25bc17a815b3db52b7"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.9.0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "abbbb9ec3afd783a7cbd82ef01dcd088ea051398"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.1"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HiGHS]]
deps = ["HiGHS_jll", "MathOptInterface", "PrecompileTools", "SparseArrays"]
git-tree-sha1 = "f869b0a17d1a4f13aac08af8d0a050bdb70bccfd"
uuid = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
version = "1.8.1"

[[deps.HiGHS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "f596ee3668df8587158bcaef1ae47bf75bc0fe39"
uuid = "8fd58aa0-07eb-5a78-9b36-339c94fd15ea"
version = "1.6.0+1"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "eb8fed28f4994600e29beef49744639d985a04b2"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.16"

[[deps.Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ca0f6bf568b4bfc807e7537f081c81e35ceca114"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.10.0+0"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "f218fe3736ddf977e0e772bc9a586b2383da2685"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.23"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "8b72179abc660bfab5e28472e019392b97d0985c"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.4"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.Inflate]]
git-tree-sha1 = "ea8031dea4aff6bd41f1df8f2fdfb25b33626381"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.4"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5fdf2fe6724d8caabf43b557b84ce53f3b7e2f6b"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2024.0.2+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IntervalSets]]
git-tree-sha1 = "dba9ddf07f77f60450fe5d2e2beb9854d9a49bd0"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.10"
weakdeps = ["Random", "RecipesBase", "Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

[[deps.Ipopt]]
deps = ["Ipopt_jll", "LinearAlgebra", "MathOptInterface", "OpenBLAS32_jll", "PrecompileTools"]
git-tree-sha1 = "6600353576cee7e7388e57e94115f6aee034fb1c"
uuid = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
version = "1.6.1"

[[deps.Ipopt_jll]]
deps = ["ASL_jll", "Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "MUMPS_seq_jll", "SPRAL_jll", "libblastrampoline_jll"]
git-tree-sha1 = "546c40fd3718c65d48296dd6cec98af9904e3ca4"
uuid = "9cc047cb-c261-5740-88fc-0cf96f7bdcc7"
version = "300.1400.1400+0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "a53ebe394b71470c7f97c2e7e170d51df21b17af"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.7"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "60b1194df0a3298f460063de985eae7b01bc011a"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.1+0"

[[deps.JuMP]]
deps = ["LinearAlgebra", "MacroTools", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays"]
git-tree-sha1 = "5036b4cf6d85b08d80de09ef65b4d951f6e68659"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.19.0"

    [deps.JuMP.extensions]
    JuMPDimensionalDataExt = "DimensionalData"

    [deps.JuMP.weakdeps]
    DimensionalData = "0703355e-b756-11e9-17c0-8b28908087d0"

[[deps.KLU]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse_jll"]
git-tree-sha1 = "07649c499349dad9f08dde4243a4c597064663e9"
uuid = "ef3ab10e-7fda-4108-b977-705223b18434"
version = "0.6.0"

[[deps.Krylov]]
deps = ["LinearAlgebra", "Printf", "SparseArrays"]
git-tree-sha1 = "8a6837ec02fe5fb3def1abc907bb802ef11a0729"
uuid = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
version = "0.9.5"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d986ce2d884d49126836ea94ed5bfb0f12679713"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.LabelledArrays]]
deps = ["ArrayInterface", "ChainRulesCore", "ForwardDiff", "LinearAlgebra", "MacroTools", "PreallocationTools", "RecursiveArrayTools", "StaticArrays"]
git-tree-sha1 = "d1f981fba6eb3ec393eede4821bca3f2b7592cd4"
uuid = "2ee39098-c373-598a-b85f-a56591580800"
version = "1.15.1"

[[deps.LambertW]]
git-tree-sha1 = "c5ffc834de5d61d00d2b0e18c96267cffc21f648"
uuid = "984bce1d-4616-540c-a9ee-88d1112d94c9"
version = "0.4.6"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "f428ae552340899a935973270b8d98e5a31c49fe"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.1"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "62edfee3211981241b57ff1cedf4d74d79519277"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.15"

[[deps.LazyArrays]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "MacroTools", "MatrixFactorizations", "SparseArrays"]
git-tree-sha1 = "9cfca23ab83b0dfac93cb1a1ef3331ab9fe596a5"
uuid = "5078a376-72f3-5289-bfd5-ec5146d43c02"
version = "1.8.3"
weakdeps = ["StaticArrays"]

    [deps.LazyArrays.extensions]
    LazyArraysStaticArraysExt = "StaticArrays"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "2da088d113af58221c52828a80378e16be7d037a"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.5.1+1"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "7bbea35cec17305fc70a0e5b4641477dc0789d9d"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.2.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LinearSolve]]
deps = ["ArrayInterface", "ChainRulesCore", "ConcreteStructs", "DocStringExtensions", "EnumX", "FastLapackInterface", "GPUArraysCore", "InteractiveUtils", "KLU", "Krylov", "Libdl", "LinearAlgebra", "MKL_jll", "Markdown", "PrecompileTools", "Preferences", "RecursiveFactorization", "Reexport", "SciMLBase", "SciMLOperators", "Setfield", "SparseArrays", "Sparspak", "StaticArraysCore", "UnPack"]
git-tree-sha1 = "73d8f61f8d27f279edfbafc93faaea93ea447e94"
uuid = "7ed4a6bd-45f5-4d41-b270-4a48e9bafcae"
version = "2.27.0"

    [deps.LinearSolve.extensions]
    LinearSolveBandedMatricesExt = "BandedMatrices"
    LinearSolveBlockDiagonalsExt = "BlockDiagonals"
    LinearSolveCUDAExt = "CUDA"
    LinearSolveEnzymeExt = ["Enzyme", "EnzymeCore"]
    LinearSolveFastAlmostBandedMatricesExt = ["FastAlmostBandedMatrices"]
    LinearSolveHYPREExt = "HYPRE"
    LinearSolveIterativeSolversExt = "IterativeSolvers"
    LinearSolveKernelAbstractionsExt = "KernelAbstractions"
    LinearSolveKrylovKitExt = "KrylovKit"
    LinearSolveMetalExt = "Metal"
    LinearSolvePardisoExt = "Pardiso"
    LinearSolveRecursiveArrayToolsExt = "RecursiveArrayTools"

    [deps.LinearSolve.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockDiagonals = "0a1fb500-61f7-11e9-3c65-f5ef3456f9f0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FastAlmostBandedMatrices = "9d29842c-ecb8-4973-b1e9-a27b1157504e"
    HYPRE = "b5ffcf37-a2bd-41ab-a3da-4bd9bc8ad771"
    IterativeSolvers = "42fd0dbc-a981-5370-80f2-aaf504508153"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    KrylovKit = "0b1a1467-8014-51b9-945f-bf0ae24f4b77"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    Pardiso = "46dd5b70-b6fb-5a00-ae2d-e8fea33afaf2"
    RecursiveArrayTools = "731186ca-8d62-57ce-b412-fbd966d074cd"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "7d6dd4e9212aebaeed356de34ccf262a3cd415aa"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.26"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "c1dd6d7978c12545b4179fb6153b9250c96b0075"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.3"

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "CPUSummary", "CloseOpenIntervals", "DocStringExtensions", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "PrecompileTools", "SIMDTypes", "SLEEFPirates", "Static", "StaticArrayInterface", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "0f5648fbae0d015e3abe5867bca2b362f67a5894"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.166"
weakdeps = ["ChainRulesCore", "ForwardDiff", "SpecialFunctions"]

    [deps.LoopVectorization.extensions]
    ForwardDiffExt = ["ChainRulesCore", "ForwardDiff"]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.METIS_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "1fd0a97409e418b78c53fac671cf4622efdf0f21"
uuid = "d00139f3-1899-568f-a2f0-47f597d42d70"
version = "5.1.2+0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "72dc3cf284559eb8f53aa593fe62cb33f83ed0c0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2024.0.0+0"

[[deps.MUMPS_seq_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "METIS_jll", "libblastrampoline_jll"]
git-tree-sha1 = "840b83c65b27e308095c139a457373850b2f5977"
uuid = "d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d"
version = "500.600.201+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "2fa9ee3e63fd3a4f7a9a4f4744a52f4856de82df"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.13"

[[deps.ManualMemory]]
git-tree-sha1 = "bcaef4fc7a0cfe2cba636d84cda54b5e4e4ca3cd"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.8"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "8b40681684df46785a0012d352982e22ac3be59e"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.25.2"

[[deps.MatrixFactorizations]]
deps = ["ArrayLayouts", "LinearAlgebra", "Printf", "Random"]
git-tree-sha1 = "78f6e33434939b0ac9ba1df81e6d005ee85a7396"
uuid = "a3b82374-2e81-5b9e-98ce-41277c0e4c87"
version = "2.1.0"

[[deps.MaybeInplace]]
deps = ["ArrayInterface", "LinearAlgebra", "MacroTools", "SparseArrays"]
git-tree-sha1 = "a85c6a98c9e5a2a7046bc1bb89f28a3241e1de4d"
uuid = "bb5d69b7-63fc-4a16-80bd-7e42200c7bdb"
version = "0.1.1"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.MuladdMacro]]
git-tree-sha1 = "cac9cc5499c25554cba55cd3c30543cff5ca4fab"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.4"

[[deps.MultivariatePolynomials]]
deps = ["ChainRulesCore", "DataStructures", "LinearAlgebra", "MutableArithmetics"]
git-tree-sha1 = "769c9175942d91ed9b83fa929eee4fe6a1d128ad"
uuid = "102ac46a-7ee4-5c85-9060-abc95bfdeaa3"
version = "0.5.4"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "806eea990fb41f9b36f1253e5697aa645bf6a9f8"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.4.0"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "a0b464d183da839699f4c79e7606d9d186ec172c"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.3"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.NonlinearSolve]]
deps = ["ADTypes", "ArrayInterface", "ConcreteStructs", "DiffEqBase", "FastBroadcast", "FastClosures", "FiniteDiff", "ForwardDiff", "LazyArrays", "LineSearches", "LinearAlgebra", "LinearSolve", "MaybeInplace", "PrecompileTools", "Preferences", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SimpleNonlinearSolve", "SparseArrays", "SparseDiffTools", "StaticArraysCore", "TimerOutputs"]
git-tree-sha1 = "d52bac2b94358b4b960cbfb896d5193d67f3ff09"
uuid = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
version = "3.8.0"

    [deps.NonlinearSolve.extensions]
    NonlinearSolveBandedMatricesExt = "BandedMatrices"
    NonlinearSolveFastLevenbergMarquardtExt = "FastLevenbergMarquardt"
    NonlinearSolveFixedPointAccelerationExt = "FixedPointAcceleration"
    NonlinearSolveLeastSquaresOptimExt = "LeastSquaresOptim"
    NonlinearSolveMINPACKExt = "MINPACK"
    NonlinearSolveNLSolversExt = "NLSolvers"
    NonlinearSolveNLsolveExt = "NLsolve"
    NonlinearSolveSIAMFANLEquationsExt = "SIAMFANLEquations"
    NonlinearSolveSpeedMappingExt = "SpeedMapping"
    NonlinearSolveSymbolicsExt = "Symbolics"
    NonlinearSolveZygoteExt = "Zygote"

    [deps.NonlinearSolve.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    FastLevenbergMarquardt = "7a0df574-e128-4d35-8cbd-3d84502bf7ce"
    FixedPointAcceleration = "817d07cb-a79a-5c30-9a31-890123675176"
    LeastSquaresOptim = "0fc2ff8b-aaa3-5acd-a817-1944a5e08891"
    MINPACK = "4854310b-de5a-5eb6-a2a5-c1dee2bd17f9"
    NLSolvers = "337daf1e-9722-11e9-073e-8b9effe078ba"
    NLsolve = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
    SIAMFANLEquations = "084e46ad-d928-497d-ad5e-07fa361a48c4"
    SpeedMapping = "f1835b91-879b-4a3f-a438-e4baacf14412"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.OffsetArrays]]
git-tree-sha1 = "6a731f2b5c03157418a20c12195eb4b74c8f8621"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.13.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS32_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6065c4cff8fee6c6770b277af45d5082baacdba1"
uuid = "656ef2d0-ae68-5445-9ca0-591084a874a2"
version = "0.3.24+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "51901a49222b09e3743c65b8847687ae5fc78eb2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "60e3045590bd104a16fefb12836c00c0ef8c7f8c"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.13+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "949347156c25054de2db3b166c52ac4728cbad65"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.31"

[[deps.PackageExtensionCompat]]
git-tree-sha1 = "fb28e33b8a95c4cee25ce296c817d89cc2e53518"
uuid = "65ce6f38-6b18-4e1d-a461-8949797d7930"
version = "1.0.2"
weakdeps = ["Requires", "TOML"]

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "64779bc4c9784fee475689a1752ef4d5747c5e87"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.42.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "1f03a2d339f42dca4a4da149c7e15e9b896ad899"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.1.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "862942baf5663da528f66d24996eb6da85218e76"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.0"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "c4fa93d7d66acad8f6f4ff439576da9d2e890ee0"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.40.1"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "68723afdb616445c6caaef6255067a8339f91325"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.55"

[[deps.Polyester]]
deps = ["ArrayInterface", "BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "ManualMemory", "PolyesterWeave", "Requires", "Static", "StaticArrayInterface", "StrideArraysCore", "ThreadingUtilities"]
git-tree-sha1 = "fca25670784a1ae44546bcb17288218310af2778"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.7.9"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "240d7170f5ffdb285f9427b92333c3463bf65bf6"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.2.1"

[[deps.PreallocationTools]]
deps = ["Adapt", "ArrayInterface", "ForwardDiff"]
git-tree-sha1 = "b6665214f2d0739f2d09a17474dd443b9139784a"
uuid = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
version = "0.4.20"

    [deps.PreallocationTools.extensions]
    PreallocationToolsReverseDiffExt = "ReverseDiff"

    [deps.PreallocationTools.weakdeps]
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "37b7bb7aabf9a085e0044307e1717436117f2b3b"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.5.3+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9b23c31e76e333e6fb4c1595ae6afa74966a729e"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.9.4"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "DocStringExtensions", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "SparseArrays", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables"]
git-tree-sha1 = "dc428bb59c20dafd1ec500c3432b9e3d7e78e7f3"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "3.10.1"

    [deps.RecursiveArrayTools.extensions]
    RecursiveArrayToolsFastBroadcastExt = "FastBroadcast"
    RecursiveArrayToolsForwardDiffExt = "ForwardDiff"
    RecursiveArrayToolsMeasurementsExt = "Measurements"
    RecursiveArrayToolsMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    RecursiveArrayToolsReverseDiffExt = ["ReverseDiff", "Zygote"]
    RecursiveArrayToolsTrackerExt = "Tracker"
    RecursiveArrayToolsZygoteExt = "Zygote"

    [deps.RecursiveArrayTools.weakdeps]
    FastBroadcast = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.RecursiveFactorization]]
deps = ["LinearAlgebra", "LoopVectorization", "Polyester", "PrecompileTools", "StrideArraysCore", "TriangularSolve"]
git-tree-sha1 = "8bc86c78c7d8e2a5fe559e3721c0f9c9e303b2ed"
uuid = "f2c3362d-daeb-58d1-803e-2bc74f2840b4"
version = "0.2.21"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "f65dcb5fa46aee0cf9ed6274ccbd597adc49aa7b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.1"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6ed52fdd3382cf21947b15e8870ac0ddbff736da"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.4.0+0"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "6aacc5eefe8415f47b3e34214c1d79d2674a0ba2"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.12"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "3aac6d68c5e57449f5b9b865c9ba50ac2970c4cf"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.42"

[[deps.SPRAL_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "Libdl", "METIS_jll", "libblastrampoline_jll"]
git-tree-sha1 = "34b9dacd687cace8aa4d550e3e9bb8615f1a61e9"
uuid = "319450e9-13b8-58e8-aa9f-8fd1420848ab"
version = "2024.1.18+0"

[[deps.SciMLBase]]
deps = ["ADTypes", "ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "EnumX", "FunctionWrappersWrappers", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "Markdown", "PrecompileTools", "Preferences", "Printf", "RecipesBase", "RecursiveArrayTools", "Reexport", "RuntimeGeneratedFunctions", "SciMLOperators", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables"]
git-tree-sha1 = "3a281a9fce9cd62b849d7f16e412933a5fe755cb"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "2.29.0"

    [deps.SciMLBase.extensions]
    SciMLBaseChainRulesCoreExt = "ChainRulesCore"
    SciMLBaseMakieExt = "Makie"
    SciMLBasePartialFunctionsExt = "PartialFunctions"
    SciMLBasePyCallExt = "PyCall"
    SciMLBasePythonCallExt = "PythonCall"
    SciMLBaseRCallExt = "RCall"
    SciMLBaseZygoteExt = "Zygote"

    [deps.SciMLBase.weakdeps]
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    PartialFunctions = "570af359-4316-4cb7-8c74-252c00c2016b"
    PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
    PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
    RCall = "6f49c342-dc21-5d91-9882-a32aef131414"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.SciMLOperators]]
deps = ["ArrayInterface", "DocStringExtensions", "LinearAlgebra", "MacroTools", "Setfield", "SparseArrays", "StaticArraysCore"]
git-tree-sha1 = "10499f619ef6e890f3f4a38914481cc868689cd5"
uuid = "c0aeaf25-5076-4817-a8d5-81caf7dfa961"
version = "0.3.8"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SimpleNonlinearSolve]]
deps = ["ADTypes", "ArrayInterface", "ConcreteStructs", "DiffEqBase", "FastClosures", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "MaybeInplace", "PrecompileTools", "Reexport", "SciMLBase", "StaticArraysCore"]
git-tree-sha1 = "873a1bf90744acfa615e45cd5dddfd0ee89a094f"
uuid = "727e6d20-b764-4bd8-a329-72de5adea6c7"
version = "1.5.0"

    [deps.SimpleNonlinearSolve.extensions]
    SimpleNonlinearSolveChainRulesCoreExt = "ChainRulesCore"
    SimpleNonlinearSolvePolyesterForwardDiffExt = "PolyesterForwardDiff"
    SimpleNonlinearSolveStaticArraysExt = "StaticArrays"

    [deps.SimpleNonlinearSolve.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.SparseDiffTools]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "Compat", "DataStructures", "FiniteDiff", "ForwardDiff", "Graphs", "LinearAlgebra", "PackageExtensionCompat", "Random", "Reexport", "SciMLOperators", "Setfield", "SparseArrays", "StaticArrayInterface", "StaticArrays", "Tricks", "UnPack", "VertexSafeGraphs"]
git-tree-sha1 = "a616ac46c38da60ac05cecf52064d44732edd05e"
uuid = "47a9eef4-7e08-11e9-0b38-333d64bd3804"
version = "2.17.0"

    [deps.SparseDiffTools.extensions]
    SparseDiffToolsEnzymeExt = "Enzyme"
    SparseDiffToolsPolyesterExt = "Polyester"
    SparseDiffToolsPolyesterForwardDiffExt = "PolyesterForwardDiff"
    SparseDiffToolsSymbolicsExt = "Symbolics"
    SparseDiffToolsZygoteExt = "Zygote"

    [deps.SparseDiffTools.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    Polyester = "f517fe37-dbe3-4b94-8317-1923a5111588"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Sparspak]]
deps = ["Libdl", "LinearAlgebra", "Logging", "OffsetArrays", "Printf", "SparseArrays", "Test"]
git-tree-sha1 = "342cf4b449c299d8d1ceaf00b7a49f4fbc7940e7"
uuid = "e56a9233-b9d6-4f03-8d0f-1825330902ac"
version = "0.3.9"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e2cfc4012a19088254b3950b85c3c1d8882d864d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.1"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "d2fdac9ff3906e27f7a618d47b676941baa6c80c"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.8.10"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "PrecompileTools", "Requires", "SparseArrays", "Static", "SuiteSparse"]
git-tree-sha1 = "5d66818a39bb04bf328e92bc933ec5b4ee88e436"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.5.0"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "bf074c045d3d5ffd956fa0a461da38a44685d6b2"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.3"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "36b3d696ce6366023a0ea192b4cd442268995a0d"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "1d77abd07f617c4868c33d4f5b9e1dbb2643c9cf"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.2"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "cef0472124fab0695b58ca35a77c6fb942fdab8a"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.1"

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

    [deps.StatsFuns.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.StrideArraysCore]]
deps = ["ArrayInterface", "CloseOpenIntervals", "IfElse", "LayoutPointers", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface", "ThreadingUtilities"]
git-tree-sha1 = "d6415f66f3d89c615929af907fdc6a3e17af0d8c"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.5.2"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.SymbolicIndexingInterface]]
git-tree-sha1 = "251bb311585143931a306175c3b7ced220300578"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"
version = "0.3.8"

[[deps.SymbolicUtils]]
deps = ["AbstractTrees", "Bijections", "ChainRulesCore", "Combinatorics", "ConstructionBase", "DataStructures", "DocStringExtensions", "DynamicPolynomials", "IfElse", "LabelledArrays", "LinearAlgebra", "MultivariatePolynomials", "NaNMath", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "SymbolicIndexingInterface", "TimerOutputs", "Unityper"]
git-tree-sha1 = "849b1dfb1680a9e9f2c6023f79a49b694fb6d0da"
uuid = "d1185830-fcd6-423d-90d6-eec64667417b"
version = "1.5.0"

[[deps.Symbolics]]
deps = ["ArrayInterface", "Bijections", "ConstructionBase", "DataStructures", "DiffRules", "Distributions", "DocStringExtensions", "DomainSets", "DynamicPolynomials", "ForwardDiff", "IfElse", "LaTeXStrings", "LambertW", "Latexify", "Libdl", "LinearAlgebra", "LogExpFunctions", "MacroTools", "Markdown", "NaNMath", "PrecompileTools", "RecipesBase", "Reexport", "Requires", "RuntimeGeneratedFunctions", "SciMLBase", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "SymbolicIndexingInterface", "SymbolicUtils"]
git-tree-sha1 = "febe1df0dc665c874cbf6fd88283603201749509"
uuid = "0c5d862f-8b57-4792-8d23-62f2024744c7"
version = "5.22.1"

    [deps.Symbolics.extensions]
    SymbolicsGroebnerExt = "Groebner"
    SymbolicsPreallocationToolsExt = "PreallocationTools"
    SymbolicsSymPyExt = "SymPy"

    [deps.Symbolics.weakdeps]
    Groebner = "0b43b601-686d-58a3-8a1c-6623616c7cd4"
    PreallocationTools = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
    SymPy = "24249f21-da20-56a4-8eb1-6a02cf4ae2e6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "eda08f7e9818eb53661b3deb74e3159460dfbc27"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.5.2"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "f548a9e9c490030e545f72074a41edfd0e5bcdd7"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.23"

[[deps.TranscodingStreams]]
git-tree-sha1 = "54194d92959d8ebaa8e26227dbe3cdefcdcd594f"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.3"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.TriangularSolve]]
deps = ["CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "LoopVectorization", "Polyester", "Static", "VectorizationBase"]
git-tree-sha1 = "fadebab77bf3ae041f77346dd1c290173da5a443"
uuid = "d5829a12-d9aa-46ab-831f-fb7c9ab06edf"
version = "0.1.20"

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.TruncatedStacktraces]]
deps = ["InteractiveUtils", "MacroTools", "Preferences"]
git-tree-sha1 = "ea3e54c2bdde39062abf5a9758a23735558705e1"
uuid = "781d530d-4396-4725-bb49-402e4bee1e77"
version = "1.4.0"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "3c793be6df9dd77a0cf49d80984ef9ff996948fa"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.19.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "e2d817cc500e960fdbafcf988ac8436ba3208bfd"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.3"

[[deps.Unityper]]
deps = ["ConstructionBase"]
git-tree-sha1 = "25008b734a03736c41e2a7dc314ecb95bd6bbdb0"
uuid = "a7c27f48-0311-42f6-a7f8-2c11e75eb415"
version = "0.1.6"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "7209df901e6ed7489fe9b7aa3e46fb788e15db85"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.65"

[[deps.VertexSafeGraphs]]
deps = ["Graphs"]
git-tree-sha1 = "8351f8d73d7e880bfc042a8b6922684ebeafb35c"
uuid = "19fa3120-7c27-5ec5-8db8-b0b0aa330d6f"
version = "0.2.0"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "7558e29847e99bc3f04d6569e82d0f5c54460703"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+1"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "93f43ab61b16ddfb2fd3bb13b3ce241cafb0e6c9"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.31.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "801cbe47eae69adc50f36c3caec4758d2650741b"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.12.2+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "522b8414d40c4cbbab8dee346ac3a09f9768f25d"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.4.5+0"

[[deps.Xorg_libICE_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "e5becd4411063bdcac16be8b66fc2f9f6f1e8fe5"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.0.10+1"

[[deps.Xorg_libSM_jll]]
deps = ["Libdl", "Pkg", "Xorg_libICE_jll"]
git-tree-sha1 = "4a9d9e4c180e1e8119b5ffc224a7b59d3a7f7e18"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.3+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "b4bfde5d5b652e22b9c790ad00af08b6d042b97d"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.15.0+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "730eeca102434283c50ccf7d1ecdadf521a765a4"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+0"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "330f955bc41bb8f5270a369c473fc4a5a4e4d3cb"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "49ce682769cd5de6c72dcf1b94ed7790cd08974c"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.5+0"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a68c9655fbe6dfcab3d972808f1aafec151ce3f8"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.43.0+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3516a5630f741c9eecb3720b1ec9d8edc3ecc033"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.1.1+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "93284c28274d9e75218a416c65ec49d0e0fcdf3d"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.40+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9c304562909ab2bab0262639bd4f444d7bc2be37"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+1"
"""

# ╔═╡ Cell order:
# ╟─fbbae78d-ad90-4ca7-9e97-cce7796eec48
# ╟─5c20b5fa-31bf-468b-85d2-1d48397ea552
# ╟─cc694ffa-ecda-492d-a8aa-e4c356182a03
# ╟─71cc7ea4-8a1a-46ff-8429-bc86860ab67d
# ╟─e8d90800-4bdd-4512-ab9c-92ae96232f8c
# ╠═af6e2d6b-7edc-4650-b909-3e5991e22abb
# ╟─872ac264-8ad4-4726-8e3f-7d3067b9cf62
# ╟─23db1b65-5377-460c-a4f4-fc79274455de
# ╟─618a5356-526d-41f1-83b7-f01e6c377b7b
# ╟─8f074aab-7f6a-4dc5-bf43-1a5650ec1c2e
# ╟─ed9ef14b-df56-4b5e-a176-29876cbd3055
# ╟─a60a1aa9-0b27-4c28-8386-a15bdaa2fe28
# ╟─a14cf195-bc83-4003-aac4-a6ab8b59fbdb
# ╠═9f402990-6c34-4b16-8968-d55f6a523d73
# ╟─8b997cc9-6f72-45bd-ac50-64377f75b94a
# ╟─642b4eff-8601-4ab3-9c81-13c600eb8d83
# ╠═1c24e128-7998-487d-a702-d4fa07ffd824
# ╟─60596838-ca36-44d1-8945-c0d5beb51352
# ╟─3ed35935-3fa1-44f5-89b9-0bab98129abe
# ╟─a797bc8e-d269-46d5-9792-dff51fc6a91d
# ╟─7e900647-e813-4048-b41d-554edb5e9fd0
# ╠═079522cf-7f45-46f3-b7d4-9457ac152712
# ╟─caf4ec4a-2ed2-45c3-933a-ebf3565423c6
# ╠═25024b3d-3efa-468c-af58-2f71c9343f4c
# ╟─06dd3a31-241a-42e2-bd79-2fe3fc42431b
# ╟─c340930f-0e86-4db6-92ed-b950679ce212
# ╟─30c25578-a317-469f-9eba-9f60016d1112
# ╟─83279d1a-899b-4e61-9e3d-b8545e1aca28
# ╟─1f5b4a38-cb54-436c-8313-eafcbad27d85
# ╟─1ad6d5b8-656c-416e-883c-0ccbee9767c4
# ╟─65d970e8-8868-4176-9715-7ebfa3ec7f40
# ╠═c5167913-d173-4c0e-902c-caf72d952862
# ╟─e212d318-fb3f-4844-b29d-e22965577b76
# ╠═485ef383-6611-4ef4-a8c9-157a10f4a72b
# ╟─fc2d6469-4819-4057-a916-7ac6fcf66ea5
# ╟─0671bb10-76e3-4f7e-a3b6-96caf5a070b0
# ╟─1c1bc517-024a-4ca9-8348-0d5efa6c7ed8
# ╟─86f41264-49c6-4dd6-a3bd-8a61cdb4c22a
# ╟─fc96902a-eecb-4d9d-a698-bafdeab6e6ba
# ╠═f5540b83-0a1f-4eb6-aa37-8b55ba12c8e9
# ╟─b770509e-02f4-471d-a6ea-3027cfe7ecb3
# ╟─193bce30-2e11-47b6-8d34-79ea396c3034
# ╟─c23bbd07-06a4-4d31-b657-f1127ac56a43
# ╠═6615890a-a5c7-495d-8a62-86a26409784b
# ╟─3d331b72-2956-4128-9640-7724a939daac
# ╟─2b4fdfd0-805e-4df2-bb6c-d6515f08bf1d
# ╟─4a785bd1-3425-464a-af96-68671db569c3
# ╟─5b197020-0e19-4a55-911c-97effb9c2f1a
# ╟─8f74a55d-cbdb-4f05-95a1-96d9be27d2e2
# ╟─d5a02d24-26f5-492d-a708-873c9a7b52ad
# ╟─a9254790-cf6d-43bf-b5d3-4651b39e8c71
# ╟─7cac9247-5b78-4a9c-ad7c-88fa4c9445f8
# ╟─46b16316-cbdc-4165-84ad-37b896067c4e
# ╟─698ba26d-219c-4f9d-8cff-c959e28f94b7
# ╟─5f72f759-e632-44b6-b051-bd831f2ffae7
# ╟─5deaf9ac-444d-4555-8e1d-7db3634e9ca0
# ╟─7a0e19df-c652-4c12-a3c1-c4d91807622b
# ╟─fd68a71f-3055-43f1-8015-e99f5cdead9e
# ╟─52f09e05-f5f2-44ac-855f-fd03cb0e21fe
# ╟─68a8f065-bd02-45e2-a0e4-bebce750f733
# ╟─7b420807-ba90-4445-8ee5-57dd682027f0
# ╟─b78ac359-0208-4311-96af-9e026eb8fe86
# ╟─24a4a121-92ab-4766-9b0c-ff0bd3dcfa51
# ╟─1eca3903-f777-400d-8e86-d85ca40f2354
# ╟─ad4d0e42-07bf-43b0-8ef8-f87208d88faf
# ╟─111cfd65-7dec-4c4b-aa7d-f7c53a47f3a6
# ╟─e2986fb8-ac1c-4591-aa7d-57919815b243
# ╟─4af8b8c2-ef21-4143-ad6c-f056c90f8854
# ╟─72cf0a7d-36fa-4533-9257-ed4f56a12374
# ╟─c9a1b17b-8cb2-4025-96b1-0064e090c5f8
# ╟─9884c49e-4b4e-4f01-894e-0453710ac997
# ╟─3f66b21e-e20c-4c36-99d8-9ae934b8df0f
# ╟─a10353ef-7267-41a9-9620-d6829b0b0c6c
# ╠═8df3e745-dde4-4f85-ba43-ae46ec5e669a
# ╠═3c9eb960-d2b6-11ee-17eb-d9e0160a1c01
# ╟─0a350a34-3c76-4de1-ad48-c05b0d7cefee
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
