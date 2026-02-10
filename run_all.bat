@echo off
REM === 指令集定义 ===
set UI_INSTS=sw lw add addi sub and andi or ori xor xori sll srl sra slli srli srai slt slti sltu sltiu beq bne blt bge bltu bgeu jal jalr lui auipc lh lhu sh sb lb lbu
set MI_INSTS=csr scall

REM === 仿真前编译 ===
vlog -sv rtl/*.v test/*.v
if errorlevel 1 (
    echo Compile failed!
    exit /b 1
)

REM === UI 指令集批量仿真 ===
for %%i in (%UI_INSTS%) do (
    echo.
    echo ====== Simulating rv32ui-p-%%i ======
    copy /Y "hex\riscv-tests\rv32ui-p-%%i.hex" "hex\riscv-tests\rv32-p-riscv.hex" >nul
    vsim -c -do "run -all; quit -force" tb_top > sim.log
    findstr /C:"Test passed." sim.log >nul
    if errorlevel 1 (
        echo [FAILED] rv32ui-p-%%i
        echo Simulating failed on: rv32ui-p-%%i
        type sim.log
        goto :fail
    ) else (
        echo [PASSED] rv32ui-p-%%i
    )
)

REM === MI 指令集批量仿真 ===
for %%i in (%MI_INSTS%) do (
    echo.
    echo ====== Simulating rv32mi-p-%%i ======
    copy /Y "hex\riscv-tests\rv32mi-p-%%i.hex" "hex\riscv-tests\rv32-p-riscv.hex" >nul
    vsim -c -do "run -all; quit -force" tb_top > sim.log
    findstr /C:"Test passed." sim.log >nul
    if errorlevel 1 (
        echo [FAILED] rv32mi-p-%%i
        echo Simulating failed on: rv32mi-p-%%i
        type sim.log
        goto :fail
    ) else (
        echo [PASSED] rv32mi-p-%%i
    )
)

echo.
echo All tests finished!
del sim.log
pause
exit /b 0

:fail
echo.
echo failure detected during simulation.
echo See sim.log for details.
pause
exit /b 1