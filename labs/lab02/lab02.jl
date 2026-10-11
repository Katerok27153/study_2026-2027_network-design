# 1. Импорт библиотек

using Pkg
Pkg.add("Plots")   # устанавливает пакет для построения графиков
using Plots        # подключаем функции plot(), plot!(), xlabel! и т.д.
using Printf # знаки после запятой

# 2. Ввод исходных данных

print("Введите ёмкость соты C (целое число): ")
C = parse(Int, readline())

print("Введите полнодоступную часть пропускной способности соты g: ")
g = parse(Int, readline())

print("Введите интенсивность обслуживания μ: ")
mu = parse(Float64, readline())

print("Введите интенсивность λ1: ")
lambda1 = parse(Float64, readline())

print("Введите интенсивность λ2: ")
lambda2 = parse(Float64, readline())

## 2.1 Интенсивность предложенной нагрузки: ρ = λ / μ
rho1 = lambda1 / mu
rho2 = lambda2 / mu

println()
println("Введены данные: C=$C, g=$g, μ=$mu, λ1=$lambda1, λ2=$lambda2")

# 3. Функции расчёта характеристик модели

## 3.1 Стационарное распределение вероятностей состояний системы p(n)
function stationary_probability(rho1::Float64, rho2::Float64, C::Int, g::Int)
    rho_sum = rho1 + rho2

    part_sum = 0.0

    # первая сумма: n = 1,...,g
    for n in 1:g
        part_sum += rho_sum^n / factorial(big(n))
    end

    # вторая сумма: n = g+1,...,C
    for n in g+1:C
        part_sum += rho_sum^g * rho1^(n - g) / factorial(big(n))
    end

    p0 = 1.0 / part_sum # p0 - константа, общая для всех состояний

    # считаем p(n) для каждого состояния
    p = zeros(Float64, C + 1)

    for n in 0:C
        if n <= g
            # полнодоступная часть
            p[n + 1] = p0 * rho_sum^n / factorial(big(n))
        else
            # зарезервированная часть n!
            p[n + 1] = p0 * rho_sum^g * rho1^(n - g) / factorial(big(n))
        end
    end

    return p
end

## 3.2 Вероятность блокировки по времени E1
function time_blocking_probability_E1(p::Vector{Float64}, C::Int)
    return p[C + 1]
end

## 3.3 Вероятность блокировки по времени E2
function time_blocking_probability_E2(p::Vector{Float64}, C::Int, g::Int)
    return sum(p[g + 1 : C + 1])
end

## 3.4 Среднее число обслуживаемых в системе запросов
function average_requests(p::Vector{Float64}, C::Int)
    N = 0.0
    for n in 0:C
        N += n * p[n + 1]
    end
    return N
end

# 4. Расчёт и вывод стационарного распределения p(n)

p = stationary_probability(rho1, rho2, C, g)

println("=== Стационарное распределение вероятностей p(n) ===")
for n in 0:C
    @printf("p(%d) = %.10f\n", n, p[n + 1])
end

## 4.1 Проверка условия нормировки: сумма всех p(n) должна быть равна 1
total = sum(p)
println()
@printf("Сумма всех вероятностей: %.10f\n", total)

# 5. Вероятностные характеристики для введённых данных

## 5.1 Вероятность блокировки по времени E1
E1  = time_blocking_probability_E1(p, C)
@printf("Вероятность блокировки по времени E1 = %.10f\n", E1)

## 5.2 Вероятность блокировки по времени E2
E2  = time_blocking_probability_E2(p, C, g)
@printf("Вероятность блокировки по времени E2 = %.10f\n", E2)

## 5.3 Среднее число обслуживаемых запросов
N  = average_requests(p, C)
@printf("Среднее число обслуживаемых запросов N = %.10f\n", N)

# 6. Расчёт данных для графиков (задания 3 и 4)

lambda1_range = 0.5:0.5:Float64(C) # последовательность значений λ1 с шагом 0.5

E1_range  = Float64[] # 3 пустых массива (результаты для каждой точки диапазона)
E2_range  = Float64[]
N_range  = Float64[]

for lam1 in lambda1_range # цикл - перебирает каждое значение λ1 из диапазона 
    rho1_i = lam1 / mu # пересчитываем ρ1 конкретно под это значение λ1
    p_i = stationary_probability(rho1_i, rho2, C, g) # заново считаем всё распределение

    E1_i = time_blocking_probability_E1(p_i, C)
    E2_i = time_blocking_probability_E2(p_i, C, g)
    N_i  = average_requests(p_i, C)

    push!(E1_range, E1_i) # и кладём готовые числа в массивы
    push!(E2_range, E2_i)
    push!(N_range, N_i)
end

# 7. Построение графиков

## 7.1 График зависимости вероятности блокировки по времени E1 от интенсивности λ1
plot_E1 = plot(lambda1_range, E1_range,
     label = "Вероятность блокировки по времени E1",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Вероятность",
     title = "Вероятность блокировки по времени E1(λ1)",
     linewidth = 2,
     color = :blue,
     legend = :topleft)
savefig(plot_E1, "blocking_probability_E1.png")
display(plot_E1)                                

## 7.2 График зависимости вероятности блокировки по времени E2 от интенсивности λ1
plot_E2 = plot(lambda1_range, E2_range,
     label = "Вероятность блокировки по времени E2",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Вероятность",
     title = "Вероятность блокировки по времени E2(λ1)",
     linewidth = 2,
     color = :red,
     legend = :topleft)
savefig(plot_E2, "blocking_probability_E2.png")
display(plot_E2) 

#№ 7.3 График зависимости вероятности блокировки по времени E1 и E2 от интенсивности λ1
plot_E1_E2 = plot(lambda1_range, E1_range,
     label = "Вероятность блокировки по времени E1",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Вероятность",
     title = "Сравнение E1(λ1) и E2(λ1)",
     linewidth = 2,
     color = :blue,
     legend = :topleft)
plot!(lambda1_range, E2_range,
     label = "Вероятность блокировки по времени E2",
     linewidth = 2,
     color = :red)
savefig(plot_E1_E2, "blocking_probability_E1_E2.png")
display(plot_E1_E2)

#№ 7.4 График зависимости среднего числа обслуживаемых запросов N от интенсивности λ1
plot_N = plot(lambda1_range, N_range,
     label = "Среднее число обслуживаемых запросов N",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Среднее число запросов",
     title = "Среднее число запросов N(λ1)",
     linewidth = 2,
     color = :purple,
     legend = :bottomright)
savefig(plot_N, "average_requests_N.png")
display(plot_N)
