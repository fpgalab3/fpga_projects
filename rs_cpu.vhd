library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpulib.all;

entity rs_cpu is
  port(
    ARdata, PCdata  : buffer std_logic_vector(15 downto 0);
    DRdata, ACdata  : buffer std_logic_vector(7 downto 0);
    IRdata, TRdata  : buffer std_logic_vector(7 downto 0);
    RRdata          : buffer std_logic_vector(7 downto 0);
    ZRdata          : buffer std_logic;
    clock, reset    : in  std_logic;
    mOP             : buffer std_logic_vector(26 downto 0);
    addressBus      : buffer std_logic_vector(15 downto 0);
    dataBus         : buffer std_logic_vector(7 downto 0)
  );
end rs_cpu;

architecture arc of rs_cpu is

  -- εσωτερικά σήματα RAM / bus
  signal mem_q      : std_logic_vector(7 downto 0);
  signal busmem     : std_logic_vector(7 downto 0);
  signal dataBus_o  : std_logic_vector(7 downto 0);

  -- enables προς data_bus
  signal pcbus_s, drbus_s, trbus_s, rbus_s, acbus_s, membus_s : std_logic := '0';

  -- extRAM interface
  signal ram_addr   : std_logic_vector(7 downto 0);
  signal ram_we     : std_logic := '0';
  signal ram_din    : std_logic_vector(7 downto 0);

  -- alus 
  signal alus_s     : std_logic_vector(6 downto 0);
  signal acload_s, zload_s, andop_s, orop_s, notop_s, xorop_s, aczero_s, acinc_s, plus_s, minus_s : std_logic := '0';

  -- fetch
  type state_t is (S_RESET, S_FETCH1, S_FETCH2);
  signal state : state_t := S_RESET;

begin

  addressBus <= ARdata;
  dataBus    <= dataBus_o;
  ram_addr <= ARdata(7 downto 0);
  ram_din  <= busmem;
  
  -- External RAM
  u_ram : extRAM
    port map(
      clk  => clock,
      addr => ram_addr,
      we   => ram_we,
      din  => ram_din,
      dout => mem_q
    );

  -- Data bus mux
  u_bus : data_bus
    port map(
      pc_q   => PCdata(7 downto 0),  
      dr_q   => DRdata,
      tr_q   => TRdata,
      r_q    => RRdata,
      ac_q   => ACdata,
      mem_q  => mem_q,
      pcbus  => pcbus_s,
      drbus  => drbus_s,
      trbus  => trbus_s,
      rbus   => rbus_s,
      acbus  => acbus_s,
      membus => membus_s,
      dataBus_o => dataBus_o,
      busmem    => busmem
    );

  -- ALU control
  u_alus : alus
    port map(
      rbus   => rbus_s,
      acload => acload_s,
      zload  => zload_s,
      andop  => andop_s,
      orop   => orop_s,
      notop  => notop_s,
      xorop  => xorop_s,
      aczero => aczero_s,
      acinc  => acinc_s,
      plus   => plus_s,
      minus  => minus_s,
      drbus  => drbus_s,
      alus   => alus_s
    );

  -- Hardwired control 
  process(clock, reset)
  begin
    if reset = '1' then
      state    <= S_RESET;
      ARdata   <= (others => '0');
      PCdata   <= (others => '0');
      IRdata   <= (others => '0');
      DRdata   <= (others => '0');
      ACdata   <= (others => '0');
      RRdata   <= (others => '0');
      TRdata   <= (others => '0');
      ZRdata   <= '0';

    elsif rising_edge(clock) then
      pcbus_s  <= '0';
      drbus_s  <= '0';
      trbus_s  <= '0';
      rbus_s   <= '0';
      acbus_s  <= '0';
      membus_s <= '0';
      ram_we   <= '0';

      mOP <= (others => '0');

      case state is
        when S_RESET =>
          state <= S_FETCH1;

        when S_FETCH1 =>
          ARdata <= PCdata;

          
          mOP(0) <= '1'; 

          state <= S_FETCH2;

        when S_FETCH2 =>
          
          membus_s <= '1';          
          IRdata   <= mem_q;     

          
          PCdata <= std_logic_vector(unsigned(PCdata) + 1);

          
          if ACdata = x"00" then
            ZRdata <= '1';
          else
            ZRdata <= '0';
          end if;

          mOP(1) <= '1'; 
          mOP(2) <= '1'; 

          state <= S_FETCH1;

      end case;
    end if;
  end process;

end arc;
