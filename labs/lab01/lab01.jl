# 1. Импорт библиотек

using Pkg
Pkg.add("Plots")   # устанавливает пакет для построения графиков
using Plots        # подключаем функции plot(), plot!(), xlabel! и т.д.

# 2. Ввод исходных данных

print("Введите ёмкость соты C (целое число): ")
C = parse(Int, readline())

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
println("Введены данные: C=$C, μ=$mu, λ1=$lambda1, λ2=$lambda2")

# 3. Функции расчёта характеристик модели

## 3.1 Стационарное распределение вероятностей состояний системы p(n), n = 0,...,C
function stationary_probability(rho1::Float64, rho2::Float64, C::Int)
    rho_sum = rho1 + rho2

    part_sum = 0.0
    for i in 0:C #цикл по i - считаем сумму (для p0)
        part_sum += rho_sum^i / factorial(big(i))
    end
    
    p0 = 1.0 / part_sum #p0 - константа, одна на все
    
    p = zeros(Float64, C + 1)
    
    for n in 0:C #цикл по n - считаем каждое p(n)
        p[n + 1] = p0 * rho_sum^n / factorial(big(n))
    end

    return p
end

## 3.2 Вероятность блокировки по времени E
function time_blocking_probability(p::Vector{Float64}, C::Int)
    return p[C + 1]
end

## 3.3 Вероятность блокировки по вызовам для запроса
function call_blocking_probability(lambda_i::Float64, lambda1::Float64, lambda2::Float64, E::Float64)
    return (lambda_i / (lambda1 + lambda2)) * E
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

p = stationary_probability(rho1, rho2, C)

println("=== Стационарное распределение вероятностей p(n) ===")
for n in 0:C
    println("p($n) = ", p[n + 1])
end

## 4.1 Проверка условия нормировки: сумма всех p(n) должна быть равна 1
total = sum(p)
println()
println("Сумма всех вероятностей: ", total)

# 5. Вероятностные характеристики для введённых данных

## 5.1 Вероятность блокировки по времени
E = time_blocking_probability(p, C)
println("Вероятность блокировки по времени E   = ", E)

## 5.2 Вероятность блокировки по вызовам для услуги 1-го типа
B1 = call_blocking_probability(lambda1, lambda1, lambda2, E)
println("Вероятность блокировки по вызовам B1  = ", B1)

## 5.3 Вероятность блокировки по вызовам для услуги 2-го типа
B2 = call_blocking_probability(lambda2, lambda1, lambda2, E)
println("Вероятность блокировки по вызовам B2  = ", B2)

## 5.4 Среднее число обслуживаемых запросов
N = average_requests(p, C)
println("Среднее число обслуживаемых запросов N = ", N)

# 6. Расчёт данных для графиков (задания 3 и 4)

lambda1_range = 0.5:0.5:Float64(C) # последовательность значений λ1 с шагом 0.5

E_range  = Float64[] # 4 пустых массива (результаты для каждой точки диапазона)
B1_range = Float64[]
B2_range = Float64[]
N_range  = Float64[]

for lam1 in lambda1_range # цикл - перебирает каждое значение λ1 из диапазона 
    rho1_i = lam1 / mu # пересчитываем ρ1 конкретно под это значение λ1
    p_i = stationary_probability(rho1_i, rho2, C) # заново считаем всё распределение

    E_i = time_blocking_probability(p_i, C)
    push!(E_range, E_i)
    push!(B1_range, call_blocking_probability(lam1, lam1, lambda2, E_i))
    push!(B2_range, call_blocking_probability(lambda2, lam1, lambda2, E_i))
    push!(N_range, average_requests(p_i, C))
end

# 7. Построение графиков

## 7.1 График зависимости вероятности блокировки по времени E от интенсивности λ1
plot_E = plot(lambda1_range, E_range,
     label = "Вероятность блокировки по времени E",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Вероятность",
     title = "Зависимость вероятности блокировки по времени\nот интенсивности поступления запросов",
     linewidth = 2,
     color = :blue,
     legend = :topleft)
savefig(plot_E, "blocking_probability_E.png")
display(plot_E)                                

#№ 7.2 График зависимости вероятности блокировки по вызовам B1 (услуга 1-го типа) от интенсивности λ1
plot_B1 = plot(lambda1_range, B1_range,
     label = "Блокировка по вызовам, услуга 1 типа (B1)",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Вероятность",
     title = "Зависимость вероятности блокировки по вызовам\nот интенсивности поступления запросов",
     linewidth = 2,
     color = :red,
     legend = :topleft)
savefig(plot_B1, "blocking_probability_B1.png")
display(plot_B1)

#№ 7.3 График зависимости вероятности блокировки по вызовам B2 (услуга 2-го типа) от интенсивности λ2
plot_B2 = plot(lambda1_range, B2_range,
     label = "Блокировка по вызовам, услуга 2 типа (B2)",
     xlabel = "Интенсивность поступающих запросов λ2",
     ylabel = "Вероятность",
     title = "Зависимость вероятности блокировки по вызовам\nот интенсивности поступления запросов",
     linewidth = 2,
     color = :green,
     legend = :topleft)
savefig(plot_B2, "blocking_probability_B2.png")
display(plot_B2)

#№ 7.4 График зависимости среднего числа обслуживаемых запросов N от интенсивности λ1
plot_N = plot(lambda1_range, N_range,
     label = "Среднее число обслуживаемых запросов N",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Среднее число запросов",
     title = "Зависимость ср. числа обслуживаемых запросов\nот интенсивности поступления запросов",
     linewidth = 2,
     color = :purple,
     legend = :bottomright)
savefig(plot_N, "average_requests_N.png")
display(plot_N)
