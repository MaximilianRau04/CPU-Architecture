namespace PicoAsm;

internal enum PicoOps : byte
{
    // 0 ------------- //
    Nop =       /**/ 0b000000,
    Add =       /**/ 0b000010,
    AddCarry =  /**/ 0b000100,
    Sub =       /**/ 0b000110,
    SubCarry =  /**/ 0b001000,
    And =       /**/ 0b001010,
    Or =        /**/ 0b001100,
    XOr =       /**/ 0b001110,
    Compare =   /**/ 0b010000,
    Test =      /**/ 0b010010,
    Load =      /**/ 0b010100,
    Input =     /**/ 0b010110,
    Output =    /**/ 0b011000,
    Fetch =     /**/ 0b011010,
    Store =     /**/ 0b011100,
    CompareCarry = /**/ 0b011110,
    // 10 ------------ //
    RL =        /**/ 0b100000,
    RR =        /**/ 0b100010,
    SL0 =       /**/ 0b100011,
    SL1 =       /**/ 0b100100,
    SLA =       /**/ 0b100101,
    SLX =       /**/ 0b100110,
    SR0 =       /**/ 0b100111,
    SR1 =       /**/ 0b101000,
    SRA =       /**/ 0b101001,
    SRX =       /**/ 0b101010,
    TestCarry = /**/ 0b101100,
    // 11 ------------ //
    Jump =      /**/ 0b110000,
    Halt =      /**/ 0b111111
}

static class PicoOpsExtensions
{
    extension(PicoOps op)
    {
        public bool IsShiftOrRotate => op is
            PicoOps.RL or PicoOps.RR or
            PicoOps.SL0 or PicoOps.SL1 or PicoOps.SLA or PicoOps.SLX or
            PicoOps.SR0 or PicoOps.SR1 or PicoOps.SRA or PicoOps.SRX;
    }
}
