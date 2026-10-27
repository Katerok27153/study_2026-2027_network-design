# 1. Импорт библиотек

using Pkg
Pkg.add("Plots")   # устанавливает пакет для построения графиков
using Plots        # подключаем функции plot(), plot!(), xlabel! и т.д.
using Printf # знаки после запятой

# 2. Ввод исходных данных

print("Введите ёмкость соты C (целое число): ")
C = parse(Int, readline())

print("Введите интенсивность λ1: ")
lambda1 = parse(Float64, readline())

print("Введите интенсивность λ2: ")
lambda2 = parse(Float64, readline())

print("Введите длину файла θ1: ")
theta1 = parse(Float64, readline())

print("Введите длину файла θ2: ")
theta2 = parse(Float64, readline())

print("Введите максимальное число запросов n1_max: ")
n1_max = parse(Int, readline())

print("Введите максимальное число запросов n2_max: ")
n2_max = parse(Int, readline())

## 2.1 Интенсивность предложенной нагрузки: ρ = λ * θ
rho1 = lambda1 * theta1
rho2 = lambda2 * theta2

## 2.2 Доля нагрузки: a = ρ / C
a1 = rho1 / C
a2 = rho2 / C

println()
println("Введены данные: C=$C, λ1=$lambda1, λ2=$lambda2, θ1=$theta1, θ2=$theta2, n1_max=$n1_max, n2_max=$n2_max")

# 3. Функции расчёта характеристик модели

## 3.1 Стационарное распределение вероятностей состояний системы p(n1, n2)
function stationary_probability(a1::Float64, a2::Float64, n1::Int, n2::Int, n1_max::Int, n2_max::Int)
    n_sum = n1 + n2

    part_sum = 0.0

    # сумма p(0,0): пробегаем все состояния сетки (i, j)
    # границы суммирования: i от 0 до n1_max, j от 0 до n2_max
    for i in 0:n1_max 
        for j in 0:n2_max
            part_sum += factorial(big(i + j)) * ((a1^i * a2^j) / (factorial(big(i)) * factorial(big(j))))
    
        end
    end

    p0 = 1.0 / part_sum # p0 = p(0,0) - константа, общая для всех состояний

    # считаем p(n1, n2)
    p = p0 * factorial(big(n_sum)) * ((a1^n1 * a2^n2) / (factorial(big(n1)) * factorial(big(n2))))
    
    return p
end

## 3.2 Вероятность блокировки по времени E
function time_blocking_probability()
    return 0 # в двухсервисной модели с эластичным трафиком её нет
end

## 3.3 Среднее число N обслуживаемых в системе запросов
function average_requests(lambdai::Float64, thetai::Float64, lambda1::Float64, theta1::Float64, lambda2::Float64, theta2::Float64)
    sum_niz = theta1 * lambda1 + theta2 * lambda2
    N = (lambdai * thetai) / sum_niz
    return N
end

## 3.4 Среднее время T обслуживания запроса
function average_time(Ni::Float64, lambdai::Float64)
    T = Ni / lambdai
    return T
end

# 4. Расчёт и вывод стационарного распределения p(n)

total = 0.0

println("=== Стационарное распределение вероятностей p(n1, n2) ===")
for n1 in 0:n1_max
    for n2 in 0:n2_max
        p = stationary_probability(a1, a2, n1, n2, n1_max, n2_max)
        @printf("p(%d,%d) = %.10f\n", n1, n2, p)
        global total += p
    end
end

## 4.1 Проверка условия нормировки: сумма всех p(n1, n2) должна быть равна 1
println()
@printf("Сумма всех вероятностей: %.10f\n", total)

# 5. Вероятностные характеристики для введённых данных

## 5.1 Вероятность блокировки по времени E1
E1  = time_blocking_probability()
@printf("Вероятность блокировки по времени E1 = %.10f\n", E1)

## 5.2 Вероятность блокировки по времени E2
E2  = time_blocking_probability()
@printf("Вероятность блокировки по времени E2 = %.10f\n", E2)

## 5.3 Среднее число обслуживаемых запросов N1
N1  = average_requests(lambda1, theta1, lambda1, theta1, lambda2, theta2)
@printf("Среднее число обслуживаемых запросов N1 = %.10f\n", N1)

## 5.4 Среднее число обслуживаемых запросов N2
N2  = average_requests(lambda2, theta2, lambda1, theta1, lambda2, theta2)
@printf("Среднее число обслуживаемых запросов N2 = %.10f\n", N2)

## 5.5 Среднее время обслуживания запроса T1
T1  = average_time(N1, lambda1)
@printf("Среднее время обслуживания запроса T1 = %.10f\n", T1)

## 5.6 Среднее время обслуживания запроса T2
T2  = average_time(N2, lambda2)
@printf("Среднее время обслуживания запроса T2 = %.10f\n", T2)

# 6. Расчёт данных для графиков (задания 3 и 4)

lambda1_range = 0.5:0.5:Float64(C) # последовательность значений λ1 с шагом 0.5

N1_range  = Float64[] # 4 пустых массива (результаты для каждой точки диапазона)
N2_range  = Float64[]
T1_range  = Float64[]
T2_range  = Float64[]

for lam1 in lambda1_range # цикл - перебирает каждое значение λ1 из диапазона 
    
    N1_i  = average_requests(lam1, theta1, lam1, theta1, lambda2, theta2) # заново считаем
    N2_i  = average_requests(lambda2, theta2, lam1, theta1, lambda2, theta2)
    T1_i = average_time(N1_i, lam1)
    T2_i = average_time(N2_i, lambda2)
    
    push!(N1_range, N1_i) # и кладём готовые числа в массивы
    push!(N2_range, N2_i)
    push!(T1_range, T1_i)
    push!(T2_range, T2_i)
end

# 7. Построение графиков

#№ 7.1 График зависимости среднего числа обслуживаемых запросов N1 от интенсивности λ1
plot_N1 = plot(lambda1_range, N1_range,
     label = "Среднее число обслуживаемых запросов N1",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Среднее число запросов",
     title = "Среднее число запросов N1(λ1)",
     linewidth = 2,
     color = :blue,
     legend = :bottomright)
savefig(plot_N1, "average_requests_N1.png")
display(plot_N1)                                

## 7.2 График зависимости среднего числа обслуживаемых запросов N2 от интенсивности λ1
plot_N2 = plot(lambda1_range, N2_range,
     label = "Среднее число обслуживаемых запросов N2",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Среднее число запросов",
     title = "Среднее число запросов N2(λ1)",
     linewidth = 2,
     color = :red,
     legend = :bottomright)
savefig(plot_N2, "average_requests_N2.png")
display(plot_N2) 

#№ 7.3 График зависимости среднего числа обслуживаемых запросов N1 и N2 от интенсивности λ1
plot_N1_N2 = plot(lambda1_range, N1_range,
     label = "Среднее число обслуживаемых запросов N1",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Среднее число запросов",
     title = "Сравнение N1(λ1) и N2(λ1)",
     linewidth = 2,
     color = :blue,
     legend = :topleft)
plot!(lambda1_range, N2_range,
     label = "Среднее число обслуживаемых запросов N2",
     linewidth = 2,
     color = :red)
savefig(plot_N1_N2, "average_requests_N1_N2.png")
display(plot_N1_N2)

#№ 7.4 График зависимости среднего времени обслуживания запроса T1 от интенсивности λ1
plot_T1 = plot(lambda1_range, T1_range,
     label = "Среднее время обслуживания запроса T1",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Среднее время запроса",
     title = "Среднее время запроса T1(λ1)",
     linewidth = 2,
     color = :green,
     legend = :bottomright)
savefig(plot_T1, "average_time_T1.png")
display(plot_T1)

#№ 7.5 График зависимости среднего времени обслуживания запроса T2 от интенсивности λ1
plot_T2 = plot(lambda1_range, T2_range,
     label = "Среднее время обслуживания запроса T2",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Среднее время запроса",
     title = "Среднее время запроса T2(λ1)",
     linewidth = 2,
     color = :orange,
     legend = :bottomright)
savefig(plot_T2, "average_time_T2.png")
display(plot_T2)

## 7.6 График зависимости среднего времени обслуживания запроса T1 и T2 от интенсивности λ1
plot_T1_T2 = plot(lambda1_range, T1_range,
     label = "Среднее время обслуживания запроса T1",
     xlabel = "Интенсивность поступающих запросов λ1",
     ylabel = "Среднее время запроса",
     title = "Сравнение T1(λ1) и T2(λ1)",
     linewidth = 2,
     color = :green,
     legend = :topleft)
plot!(lambda1_range, T2_range,
     label = "Среднее время обслуживания запроса T2",
     linewidth = 2,
     color = :orange)
savefig(plot_T1_T2, "average_time_T1_T2.png")
display(plot_T1_T2)