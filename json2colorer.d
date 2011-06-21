module json2colorer;

import Team15.Http.Json;
import Team15.LiteXML;
import Team15.Utils;

import std.file;
import std.string;
import std.stdio;

struct DSymbol
{
	string name;
	string kind;
	string file;
	int line;
	string type;
	string comment;
	DSymbol[] members;
	string prot;
	string base;
	string[] interfaces;
}

void main(string[] args)
{
	string[][string][string] results;
	foreach (file; listdir(args[1], "*.json"))
	{
		auto symbols = jsonParse!(DSymbol[])(cast(string)read(file));
		foreach (mod; symbols)
		{
			if (mod.file.startsWith("internal") || mod.name.startsWith("std.typeinfo") || mod.name=="")
				continue;
			foreach (member; mod.members)
				if (member.prot=="public" || member.prot=="export" || member.prot=="undefined")
				{
					string name = member.name;
					if (name.contains("("))
						name = name[0..name.find("(")];
					results[member.kind][mod.name] ~= name;
				}
		}
	}

	string[] kindSort = [
		"alias",
		"typedef",
		"template",
		"struct",
		"union",
		"class",
		"interface",
		"enum",
		"enum member",
		"variable",
		"function",
	];

	foreach (kind; kindSort)
		if (kind in results)
		{
			auto modules = results[kind];
			writefln("\t<keywords region='key.lib.%s'>", kind.replace(" ", "-"));
			foreach (moduleName; modules.keys.sort)
			{
				auto symbols = modules[moduleName];
				bool[string] seen;
				writefln("\t\t<!-- %s -->", moduleName);
				foreach (symbol; symbols)
				{
					if (symbol in seen)
						continue;
					seen[symbol] = true;
					writefln("\t\t<word name='%s'/>", encodeEntities(symbol));
				}
			}
			writefln("\t</keywords>");
			writefln("\t");
		}
}
