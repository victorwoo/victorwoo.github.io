using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text;
using System.Threading;

namespace Lottery
{
    internal class Generator
    {
        private readonly IList<string> candidateList;
        private Random random = new Random();

        internal Generator(string[] candidates)
        {
            candidateList = new List<string>(candidates);
        }

        internal string Pick()
        {
            var random = new Random(); // 会导致粘连
            //var random = this.random; // 不会粘连

            int index = random.Next(candidateList.Count);
            Debug.Write(index + ", ");
            Thread.Sleep(0); // 延时，模拟电脑性能差的情况。
                              // 设为 5 时，有很多“粘连”的数据。
                              // 设为 15 时，“粘连”现象就消失了！

            string choosen = candidateList[index];
            candidateList.Remove(choosen);
            return choosen;
        }
    }

    internal class Program
    {
        private static void Main(string[] args)
        {
            string[] candidates =
            {
                "公司领导-宋江", "公司领导-卢俊义", "公司领导-吴用", "公司领导-公孙胜", "公司领导-关胜", "公司领导-林冲", "公司领导-秦明",
                "公司领导-呼延灼", "市场部-花荣", "市场部-柴进", "市场部-李应", "市场部-朱仝", "市场部-鲁智深", "测试中心-武松", "测试中心-董平", "测试中心-张清",
                "测试中心-杨志", "测试中心-徐宁", "测试中心-索超", "测试中心-戴宗", "测试中心-刘唐", "财务部-李逵", "财务部-史进", "财务部-穆弘", "财务部-雷横", "财务部-李俊",
                "财务部-阮小二", "财务部-张横", "品质管理部-阮小五", "品质管理部-张顺", "品质管理部-阮小七", "品质管理部-杨雄", "品质管理部-石秀", "品质管理部-解珍",
                "人力资源部-解宝", "人力资源部-燕青", "人力资源部-朱武", "人力资源部-黄信", "人力资源部-孙立", "人力资源部-宣赞", "人力资源部-郝思文", "系统支持部-韩滔",
                "系统支持部-彭玘", "系统支持部-单廷珪", "系统支持部-魏定国", "系统支持部-萧让", "信息中心-裴宣", "信息中心-欧鹏", "信息中心-邓飞", "信息中心-燕顺", "信息中心-杨林",
                "信息中心-凌振", "信息中心-蒋敬", "研发一部-吕方", "研发一部-郭盛", "研发一部-安道全", "研发一部-皇甫端", "研发一部-王英", "研发一部-扈三娘", "研发一部-鲍旭",
                "研发一部-樊瑞", "研发二部-孔明", "研发二部-孔亮", "研发二部-项充", "研发二部-李衮", "研发二部-金大坚", "研发二部-马麟", "研发二部-童威", "研发三部-童猛",
                "研发三部-孟康", "研发三部-侯健", "研发三部-陈达", "研发三部-杨春", "研发三部-郑天寿", "研发三部-陶宗旺", "研发三部-宋清", "研发三部-乐和", "研发三部-龚旺",
                "研发三部-丁得孙", "研发四部-穆春", "研发四部-曹正", "研发四部-宋万", "研发四部-杜迁", "研发四部-薛永", "研发四部-施恩", "研发四部-李忠", "研发四部-周通",
                "研发四部-汤隆", "研发四部-杜兴", "研发四部-邹渊", "研发五部-邹润", "研发五部-朱贵", "研发五部-朱富", "研发五部-蔡福", "研发五部-蔡庆", "研发五部-李立",
                "研发五部-李云", "研发五部-焦挺", "研发六部-石勇", "研发六部-孙新", "研发六部-顾大嫂", "研发六部-张青", "研发六部-孙二娘", "研发六部-王定六", "研发六部-郁保四",
                "研发六部-白胜", "研发六部-时迁", "研发六部-段景住"
            };
            var generator = new Generator(candidates);

            Console.WindowWidth = 100;
            while (Console.ReadKey().Key != ConsoleKey.Escape)
            {
                var sb = new StringBuilder();
                for (int i = 0; i < 5; i++)
                {
                    var choosen = generator.Pick();
                    sb.Append(choosen);
                    sb.Append('\t');
                }
                Console.WriteLine(sb.ToString().TrimEnd());
            }
        }
    }
}